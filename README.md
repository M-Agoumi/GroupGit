# GroupGit

**GroupGit** is a lightweight tool designed to help you manage and group multiple repositories under a single project. Ideal for developers managing microservices architectures or multiple related repositories, GroupGit streamlines your workflow with simple commands.

## Features

- **Group and manage multiple repositories** easily within one main project.
- **Clone, update, and sync** all repositories with a single command.
- **Simplify repository management** for complex projects.

## Installation

You can install GroupGit quickly using the following command:

```bash
curl -sL https://github.com/M-Agoumi/GroupGit/raw/main/install_groupgit.sh | sh
```

This command will download and execute the installer script directly, setting up GroupGit as a command you can use from anywhere on your system.

### Manual Installation

If you prefer to install manually:

1. Clone this repository:
   ```bash
   git clone https://github.com/M-Agoumi/GroupGit.git
   cd yourrepository
   ```

2. Run the installer script:
   ```bash
   ./install_groupgit.sh
   ```

## Usage

Once installed, you can use the `groupgit` command:

- **Initialize a Group Project**:
  ```bash
  groupgit init
  ```

- **Clone All Repositories** listed in your project:
  ```bash
  groupgit clone
  ```

- **Update Repositories** to their latest version:
  ```bash
  groupgit update
  ```

## Uninstallation

To uninstall GroupGit, simply remove the executable from `~/.local/bin`:

```bash
rm ~/.local/bin/groupgit
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please fork this repository and submit a pull request for any improvements or new features.

## Issues

If you encounter any issues, please report them in the [issues section](https://github.com/M-Agoumi/GroupGit/issues) of the repository.

---

**GroupGit** - Manage Your Repositories with Ease.