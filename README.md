# Circom Boilerplate

Welcome to **Circom Boilerplate**, your go-to toolkit for simplifying the development process with Circom. This boilerplate comes loaded with scripts, ensuring a hassle-free experience in setting up your environment, installing dependencies, and automating the entire development workflow.

## Prerequisites

- **Node.js:** Installed (Version 10 or higher)

> **Tip:**
> Don't have Node.js installed? No worries! You can easily try out this boilerplate using GitHub Codespaces. Simply click the green `<> Code` button on the repository page, select `Codespaces`, and hit the `+` button. Voilà! You'll have an online development environment tailored to this project.

## Installation

1. **Clone the Repository:**

```bash
git clone https://github.com/KumaCrypto/circom_boilerplate.git
```

or via SSH

```bash
git clone git@github.com:KumaCrypto/circom_boilerplate.git
```

2. **Navigate to the Project Directory:**

```bash
cd circom_boilerplate
```

3. **Install Dependencies:**

If you haven't installed `Rust` yet:

```bash
npm run install_rust
```

> **Note:**
> During the process you will be asked to select an installation method, select option 1 (unless you require a different one).
> After the installation, close the current terminal and open a new one to continue.

Install Circom and SnarkJS:

```bash
npm run setup
```

> **Tip:**
> For comfortable writing of circuits you can install the Circom code [highlighting extension](https://marketplace.visualstudio.com/items?itemName=iden3.circom). (More visually appealing than black and white text).

## Usage

This boilerplate offers the following scripts:

### Test Your Circuit

> Depending on your circuit, fill in the input.json file.

This script handles everything – from compiling your circuit to verifying it with a generated witness. Important: This contributes to PowersOfTau (POT) and prepares for the second phase (this might take a while).

**Conditions:**

- The circuit must be in the `circuits` folder.
- The file containing arguments for the circuit must be named `input.json` and placed at the root of the repository.

```bash
npm run test <circuit name> # Default input: input.json (change it in package.json if needed)
```

The output will be generated in the `build` directory.

### Test Circuit without POTs

Similar to the previous command, but skips the contribution to POT and second stage preparation. Faster. Use it for quick circuit tests or if you understand what you're doing.

Can be used if you already have POTs.

```bash
npm run test_no_pots <circuit name> # Default input: input.json (change it in package.json if needed)
```

### Generate Solidity contract

This command creates a `Solidity` contract to verify your circuit on-chain. Make sure to run one of the previous commands to generate the proving key (located at `build/circuit_name.zkey`).

```bash
npm run solidityVerifier <circuit name>
```

The verifying contract will be generated in the `src` directory.

## Acknowledgement ⭐️

If you find this boilerplate helpful, show your support by starring it on GitHub. It costs nothing for you but means the world to us.
Happy coding! ✨

## Contribute

- **Report Bugs:** If you encounter a bug, please open a detailed issue on GitHub, explaining how to replicate the problem.
- **Suggest Enhancements:** Have ideas to enhance this project? Feel free to propose new features or improvements by opening an issue. Your input is invaluable!

## License

This project is licensed under the MIT License - check out the [LICENSE](LICENSE) file for more details.
