<!-- documentation/IMPLEMENTATION_GUIDE.md -->
# Uformer FastAPI Hub: Advanced Implementation Guide

**Document Version:** 1.0  
**Date:** 2025-06-23<br>

**Purpose:** This document provides a detailed technical explanation of the advanced architectural patterns implemented in the Uformer FastAPI Hub. It is intended for developers, system architects, and future maintainers to understand the core logic for state management, concurrency safety, VRAM management, and automated cache handling.

---

## 1. Core Architecture: Centralized In-Memory State

To enable complex, asynchronous operations and shared state across multiple API requests and background tasks, the application relies on a single, centralized, in-memory dictionary initialized at application startup. This avoids the pitfalls of local, ephemeral variables in a concurrent environment.

**Location:** `backend/app/main.py`
**Object:** `app_models: Dict[str, Any]`

This dictionary is the **single source of truth** for all shared application state. It is injected into API endpoints via FastAPI's dependency injection system (`Depends(get_models)`).

### 1.1. State Dictionary Keys

The `app_models` dictionary contains the following critical keys:

| Key                           | Type | Purpose                                                                                                                        |
| ----------------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------ |
| `device`                      | `torch.device` | Stores the global PyTorch device (`cuda` or `cpu`).                                           |
| `load_all_on_startup`         | `bool` | Flag from `.env` that dictates the VRAM management strategy (preload vs. on-demand).                         |
| `tasks_db`                    | `Dict` | Tracks real-time status (`pending`, `processing`, `completed`, `failed`), progress, and results of all background tasks.      |
| `models_in_use`               | `Dict` | A reference counter (`{'model_name': count}`) to prevent unloading a model from VRAM while a task is actively using it.          |
| `in_progress_uploads`         | `Dict` | Tracks absolute disk paths of raw video files being processed to protect them from premature deletion.      |
| `tracker_by_path`             | `Dict` | **Primary cache tracker.** Maps a result file's relative URL path to its detailed metadata object.                           |
| `path_by_task_id`             | `Dict` | A secondary index mapping a `task_id` to a result file's path for fast lookups (e.g., for heartbeats).                                           |
| `denoise_b`, `deblur_b`, etc. | `Uformer`| When a model is loaded into VRAM, its instance is stored here under its unique model name.                                   |

---

## 2. Dynamic UI Configuration System

To decouple the frontend from the backend and allow for easy addition of new tasks or models, the backend exposes a single endpoint that provides all necessary UI configuration.

* **Endpoint:** `GET /api/available_controls`  
* **Source of Truth:** The `AVAILABLE_TASKS_AND_MODELS` and `PAGE_SPECIFIC_CONTROLS` dictionaries in `backend/app/api/dependencies.py`.  

A frontend can fetch from this endpoint on startup to dynamically build its task selection dropdowns, populate the correct model options when a task is selected, and enable/disable page-specific controls (like the "Patch Processing" checkbox) without having any hardcoded values. This makes the entire system highly modular and easy to extend.

---

## 3. VRAM Management Strategy

The system supports two distinct VRAM management strategies, controlled by the `LOAD_ALL_MODELS_ON_STARTUP` variable in the `.env` file.

### 3.1. Pre-load All (`True`)

*   **Behavior:** On application startup, all Uformer models defined in `AVAILABLE_TASKS_AND_MODELS` are loaded into GPU VRAM.
*   **Pros:** Fastest possible performance for the first user request of any model.
*   **Cons:** High initial VRAM usage.

### 3.2. On-Demand (`False`)

*   **Behavior:** Models are **NOT** loaded on startup. When an API request for a specific model is received, the `get_model_by_name` dependency loads it into VRAM and then caches it in the `app_models` dictionary.
*   **Pros:** Very low initial VRAM usage. Ideal for resource-constrained environments.
*   **Cons:** The first request for each model will have a noticeable "cold start" delay during model loading.
*   **Explicit Unloading:** Models are only unloaded from VRAM when the `/api/unload_models` endpoint is called. This prevents race conditions where one user's action could de-allocate a model another user is about to request.

### 3.3. VRAM Concurrency Protection (Reference Counting)

To prevent a model from being unloaded from VRAM while in use by another task, a reference counting system is implemented using the `models_in_use` dictionary.

*   **Increment:** When a processing task (image, video, or live stream) begins, it increments the count for its required model (e.g., `models_in_use['denoise_b'] += 1`).
*   **Decrement:** In a `finally` block (guaranteeing execution even on error), the task decrements the model's count.
*   **Check:** The `/api/unload_models` endpoint **must** check this counter. If a model's count is greater than 0, the unload operation for that model is skipped, and the user is notified.

---

## 4. Production-Ready Cache Management System

This system is designed to prevent premature file deletion while ensuring the server disk does not fill up with orphaned files.

### 4.1. Core Concepts

*   **Protection of In-Progress Uploads:** Raw video files are needed on disk for the entire duration of processing. They must be protected from manual cache clearing.
*   **Protection of Active Results:** Processed files (images/videos) should not be deleted if a user is actively viewing them.
*   **Protection of Downloaded Files:** After a user initiates a download, the file should be protected for a grace period.
*   **Automated Cleanup:** The system must automatically identify and delete "abandoned" (undownloaded) and "expired" (downloaded long ago) files.

### 4.2. The Full File Lifecycle

This flow describes the journey of a file from creation to deletion.

```text
START
  |
  V
[User Clicks "Process Video"]
  |
  +-> [Backend] POST /api/process_video
  |     |
  |     +-> Saves raw video to disk (e.g., /temp/.../uploads/video.mp4)
  |     +-> Adds its absolute path to `in_progress_uploads` tracker. [FILE IS NOW PROTECTED]
  |     +-> Starts background task, returns `task_id`.
  |
  V
[Client] Begins polling /api/video_status/{task_id}
  |
  V
[Backend Task] `video_processing_task` runs...
  |
  V
[Backend Task] Task finishes successfully.
  |     |
  |     +-> Creates final result file (e.g., /temp/.../processed/enhanced.mp4)
  |     +-> **Removes** raw upload path from `in_progress_uploads`. [UPLOAD UNPROTECTED]
  |     +-> **Adds** result's relative URL path to `tracker_by_path` with {status: 'active', ...}. [RESULT IS NOW PROTECTED]
  |     +-> Updates `tasks_db` status to 'completed'.
  |
  V
[Client] Poll receives 'completed' status.
  |     |
  |     +-> Displays the processed video.
  |     +-> **Starts** the 5-minute heartbeat poll to POST /api/task_heartbeat.
  |
  V
[User Clicks "Download"]
  |
  +-> [Client] Initiates download.
  |     |
  |     +-> **Stops** the heartbeat poll.
  |     +-> Calls POST /api/confirm_download with the result path.
  |
  V
[Backend] /api/confirm_download receives call.
  |     |
  |     +-> Finds file in `tracker_by_path`.
  |     +-> Updates status to 'downloaded' and sets `downloaded_at` timestamp. [GRACE PERIOD STARTED]
  |
  V
[Cleanup Task] Runs periodically (or is triggered manually).
      |
      +-> Checks all tracked files against deletion rules.
      +-> If (status is 'active' AND time since last heartbeat > TIMEOUT) -> DELETES FILE
      +-> If (status is 'downloaded' AND time since download > GRACE_PERIOD) -> DELETES FILE
```

### 4.3. Manual vs. Automatic Cleanup

*   **Manual (`/api/clear_cache`):** This endpoint iterates through all files on disk and applies the protection rules above to decide which files to delete. It returns a detailed JSON object (`{cleared_count, skipped_..._count}`).
*   **Automatic (`periodic_cache_cleanup_task`):** This background task is scheduled at application startup **only if `ENABLE_AUTOMATIC_CACHE_CLEANUP=True`**. It runs the exact same deletion logic as the manual cleanup on a recurring interval.

---
This document outlines the key architectural decisions that make the Uformer FastAPI Hub a robust, scalable, and user-friendly application.
