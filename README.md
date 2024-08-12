![GIF Description](ezgif-3-bc1a9cf5bb.gif)

# Belullama

Belullama: A powerful stand-alone AI application bundle!

Belullama is a comprehensive AI application that bundles Ollama, Open WebUI, and Automatic1111 (Stable Diffusion WebUI) into a single, easy-to-use package. It allows you to create and manage conversational AI applications and generate images with minimal setup.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)  
  - [Stand-alone Installation](#stand-alone-installation)  
  - [CasaOS Installation (Optional)](#casaos-installation-optional)
- [🚀 Coming Soon: NVIDIA GPU Support](#coming-soon-nvidia-gpu-support)
- [Usage](#usage)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)
- [Star History](#star-history)
- [Sources](#sources)

## Introduction

Belullama provides a complete solution for running large language models and image generation models on your local machine. It combines the power of Ollama for running LLMs, Open WebUI for a user-friendly interface, and Automatic1111 for Stable Diffusion image generation.

## Features

- **All-in-One AI Platform**: Belullama integrates Ollama, Open WebUI, and Automatic1111 (Stable Diffusion WebUI) in a single package.
- **Easy Setup**: The stand-alone version comes with a simple installer script for quick deployment.
- **Conversational AI**: Create and manage chatbots and conversational AI applications with ease.
- **Image Generation**: Generate images using Stable Diffusion models through the Automatic1111 WebUI.
- **User-Friendly Interface**: Open WebUI provides an intuitive interface for interacting with language models.
- **Offline Operation**: Run entirely offline, ensuring data privacy and security.
- **Extensibility**: Customize and extend functionalities to meet your specific requirements.


## Installation

### Stand-alone Installation

To install the stand-alone version of Belullama, which includes Ollama, Open WebUI, and Automatic1111, use the following command:

```bash
curl -s https://raw.githubusercontent.com/ai-joe-git/Belullama/main/belullama_installer.sh | sudo bash
```

This script will set up all components and configure them to work together seamlessly.

### CasaOS Installation (Optional)

![Image Description](thumbnail.png)

If you prefer to install Belullama as a CasaOS app, follow these steps:

1. Access your CasaOS server through your web browser.
2. Click the "+" button and select "Install a customized app".
3. Download the Docker file from [here](https://github.com/ai-joe-git/Belullama/blob/main/BelullamaStableDiffusionBETA.yaml).
4. In the CasaOS interface, click "Install" and follow the prompts to complete the installation.

## Coming Soon: NVIDIA GPU Support

We're excited to announce that we're actively working on an NVIDIA GPU-compatible version of Belullama! This upcoming release will allow users with NVIDIA graphics cards to leverage their GPU power for significantly faster processing and improved performance.

### 🧪 Beta Testers Needed

As we're in the final stages of development, we're looking for beta testers to help us ensure the NVIDIA version works flawlessly across different setups. If you have an NVIDIA GPU and would like to contribute to the project by being a beta tester, please try the GPU supported version:

To install the GPU version of Belullama, which includes Ollama, Open WebUI, and Automatic1111, use the following command:

```bash
curl -s https://raw.githubusercontent.com/ai-joe-git/Belullama/main/belullama_installer_gpu.sh | sudo bash
```

This script will set up all components and configure them to work together seamlessly.

### 📅 Expected Release

While we don't have a fixed release date yet, we're aiming to launch the NVIDIA-compatible version very soon. Stay tuned to this repository for updates!

### 💡 Current Version

Please note that the current version of Belullama is CPU-based. If you're eager to start using Belullama right away, you can still enjoy its features using your CPU.

We appreciate your patience and support as we work to make Belullama even more powerful and accessible. Thank you for being part of our community!

## Usage

After installation, you can start using Belullama:

1. Access Open WebUI through your web browser (the URL will be provided after installation).
2. Use the interface to interact with language models, create chatbots, or generate text.
3. To access Stable Diffusion WebUI, use the provided URL for Automatic1111.
4. Follow the on-screen instructions to generate images or fine-tune models.

For detailed usage instructions, please refer to the documentation in the Belullama repository.

## Screenshots

![Screenshot 1](screenshot-1.png)
![Screenshot 2](screenshot-2.png)



## Contributing

Contributions to Belullama are welcome! If you have ideas, bug reports, or feature requests, please open an issue in the repository. Pull requests for code improvements or new features are also appreciated.

## License

Belullama is released under the [MIT License](https://opensource.org/licenses/MIT). See the LICENSE file in the repository for details.

## Star History

<a href="https://star-history.com/#ai-joe-git/Belullama&Date"> <picture>   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=ai-joe-git/Belullama&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=ai-joe-git/Belullama&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=ai-joe-git/Belullama&type=Date" /> </picture>
</a>

## Sources

- [Ollama](https://ollama.com) - Run Llama 3, Mistral, Gemma, and other large language models locally.
- [Open-WebUI](https://openwebui.com) - User-friendly WebUI for LLMs (Formerly Ollama WebUI).
- [Automatic1111](https://github.com/AUTOMATIC1111/stable-diffusion-webui) - Stable Diffusion WebUI.
- [CasaOS](https://casaos.io) - A simple, easy-to-use, elegant open-source Personal Cloud system (optional).
