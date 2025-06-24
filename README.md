# Uformer FastAPI Hub: A Production-Ready Image & Video Enhancement Service

<a href="https://www.youtube.com/watch?v=ncc1vPxfz48">
  <img src="documentation/assets/YT-Thumbnail_uformer-fastapi-hub.png" 
       alt="Uformer FastAPI Hub Demo Video">
</a>

*Click the image above to watch the full video demonstration on YouTube ([Full Stack AI Project: A Production Uformer Service with FastAPI, Next.js & Docker](https://www.youtube.com/watch?v=ncc1vPxfz48)).*

**Uformer FastAPI Hub** is a complete, containerized, and production-ready toolkit that serves state-of-the-art [Uformer models](https://github.com/ZhendongWang6/Uformer) for image and video restoration. It provides a robust FastAPI backend with a modern Next.js frontend, designed for developers and researchers who need a reliable, resource-aware, and easy-to-deploy solution for low-level vision tasks like denoising and deblurring.

---

## Motivation

The official Uformer repository provides groundbreaking research code, but bridging the gap from research to a practical, usable tool presents several challenges:
*   **Dependency Rot:** The original environment relies on outdated dependencies, leading to significant setup friction and compatibility issues.
*   **Untested Pipeline:** The original code is not designed for easy testing or integration, making it difficult to verify results or add new models.
*   **Not a Service:** It is architected for academic evaluation, not for continuous, on-demand use as a web service.
*   **No Resource Management:** It lacks built-in mechanisms for managing GPU VRAM or disk cache, which is critical when serving multiple large models in a production environment.

This project solves these problems by re-engineering the Uformer pipeline into a robust, service-oriented architecture. We've modernized the dependencies, built a clean, test-friendly backend, and added professional-grade resource management features. The result is a turnkey solution that lets you go from clone to enhancement in minutes.

---

## Features

*   **⚡️ High-Performance FastAPI Backend:** A fully asynchronous backend capable of handling long-running image and video processing tasks without blocking.
*   **🖼️ Multi-Modal Enhancement:**
    *   **Image Processing:** Enhance individual images with support for patch-based processing for maximum quality.
    *   **Video Processing:** Asynchronously process entire video files, frame by frame.
    *   **Live Stream:** Real-time enhancement of webcam feeds via WebSockets.
*   **🧠 Multiple Uformer Models:**
    *   **Denoising (High Quality):** `Uformer-B` (584 MB) - The full-sized model for the best denoising results.
    *   **Denoising (Fast):** `Uformer-16` (61 MB) - A smaller, lighter model for faster processing, ideal for real-time applications.
    *   **Motion Deblurring:** `Uformer-B` (584 MB) - The full-sized model trained on the GoPro dataset for motion deblurring.
*   **🐳 Fully Containerized with Docker:**
    *   One-command setup with `docker-compose`.
    *   Stateless container design with volume mounts for models, logs, and temp files.
    *   Optimized, multi-stage builds for small and secure production images.
*   **🖥️ Modern Next.js Frontend:** A clean, responsive, and user-friendly interface for all features.
*   **✅ Advanced Resource Management:**
    *   **On-Demand VRAM Loading:** Models can be loaded into GPU memory on-demand to save resources, with UI controls to unload them.
    *   **Intelligent Cache System:** Automated and manual cache management to clean up temporary files, with protection for files in use.
*   **📖 Comprehensive API:** A fully documented API allows for easy integration into your own applications.

---

## Quick Start (Docker)

This is the recommended method for running the application.

### Prerequisites
*   [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
*   For GPU acceleration (highly recommended):
    *   An NVIDIA GPU
    *   The [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/uformer-fastapi-hub.git
cd uformer-fastapi-hub
```

### 2. Download Model Weights
You must download the official pre-trained models and place them in the correct directory. First, create the directory:
```bash
# Create the directory for the models
mkdir -p backend/model_weights/official_pretrained
```
Then, download the following files and place them inside that directory. Each model is optimized for a specific task based on its training data.

| Model / Task                  | File Size | Training Dataset & Best Use Case                                                                                                    | Download                                                                                                                              |
| ----------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Denoising (High Quality)**  | 584 MB    | **[SIDD](https://mailustceducn-my.sharepoint.com/:f:/g/personal/zhendongwang_mail_ustc_edu_cn/EtcRYRDGWhBIlQa3EYBp4FYBao7ZZT2dPc5k1Qe-CdPh3A)** <br/> Best for general-purpose denoising of sRGB images from digital cameras. | [Uformer_B_SIDD.pth](https://mailustceducn-my.sharepoint.com/:u:/g/personal/zhendongwang_mail_ustc_edu_cn/Ea7hMP82A0xFlOKPlQnBJy0B9gVP-1MJL75mR4QKBMGc2w?e=iOz0zz) |
| **Denoising (Fast)**          | 61 MB     | **[SIDD](https://mailustceducn-my.sharepoint.com/:f:/g/personal/zhendongwang_mail_ustc_edu_cn/EtcRYRDGWhBIlQa3EYBp4FYBao7ZZT2dPc5k1Qe-CdPh3A)** <br/> A lighter version for faster performance, ideal for real-time use.      | [uformer16_denoising_sidd.pth](https://www.kaggle.com/datasets/ekojsalim/uformer-weights/data)                                       |
| **Motion Deblurring**         | 584 MB    | **[GoPro](https://mailustceducn-my.sharepoint.com/:f:/g/personal/zhendongwang_mail_ustc_edu_cn/EqKY3WMkbfVBlzldiEe4IEUBgr6BQx8mkI9jipWoWrwqQg?e=c5aPIe)** <br/> Best for correcting blur caused by camera shake or fast motion.    | [Uformer_B_GoPro.pth](https://mailustceducn-my.sharepoint.com/:u:/g/personal/zhendongwang_mail_ustc_edu_cn/EfCPoTSEKJRAshoE6EAC_3YB7oNkbLUX6AUgWSCwoJe0oA)      |

*__Note:__ Check the original `README.md`, [UFORMER_ORIGINAL_README.md](UFORMER_ORIGINAL_README.md)*, for more datasets

---
### 3. Configure Environment
Copy the example environment file. The default settings are configured for on-demand model loading.

```bash
cp backend/.env.example backend/.env
```

### 4. Run the Application
Use Docker Compose to build and start all services.

```bash
docker-compose up --build -d
```

The application is now running!
*   **Frontend UI:** [http://localhost:3000](http://localhost:3000)
*   **Backend API Docs:** [http://localhost:8000/docs](http://localhost:8000/docs)

---

## Application Usage

Once the application is running, navigate to [http://localhost:3000](http://localhost:3000).

*   **Live Stream:** Enhance your webcam feed in real-time. Select a `task` and model, then click "Start Webcam".
*   **Video File:** Upload a video file for enhancement. Processing is done in the background. You will be notified when it's complete.
*   **Image File:** Upload an image for enhancement. High-quality patch processing is enabled by default.

### Resource Management
The header contains controls for monitoring and managing server resources:
*   **Cache Manager:** View the disk space used by temporary image and video files and clear them. The system will protect files that are still being processed or viewed.
*   **VRAM Manager:** If on-demand loading is enabled (`LOAD_ALL_MODELS_ON_STARTUP=False` in `.env`), you can see which models are currently loaded in GPU VRAM and unload them to free up memory.

---

## Project Structure

*   `frontend/`: The Next.js frontend application.
*   `backend/`: The FastAPI backend application.
    *   `app/`: Core application code, including API endpoints.
    *   `uformer_model/`: The Uformer model definition and utilities.
    *   `model_weights/`: Directory where model `.pth` files are stored (mounted via Docker volume).
    *   `temp/`: Directory for temporary files like uploads and processed results (mounted via Docker volume).
    *   `debug_logs/`: Directory for persistent application logs (mounted via Docker volume).
*   `documentation/`: Contains detailed guides for API usage and advanced implementation details.
*   `docker-compose.yml`: The master file for orchestrating the containerized application.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgements

This project would not be possible without the foundational work from the authors of Uformer.
*   **Original Paper:** [Uformer: A General U-Shaped Transformer for Image Restoration (CVPR 2022)](https://arxiv.org/abs/2106.03106)
*   **Original Codebase:** [github.com/ZhendongWang6/Uformer](https://github.com/ZhendongWang6/Uformer)
*   The original `README.md` from their repository is preserved [here (UFORMER_ORIGINAL_README.md)](UFORMER_ORIGINAL_README.md).
