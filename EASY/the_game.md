# W1seGuy XOR Decrypter (TryHackMe)

This repository contains a Python script developed to solve the cryptographic challenge found in the **W1seGuy** room on TryHackMe. The tool automates the process of breaking a repeating-key XOR cipher.

## 🚀 Project Overview

The challenge involves decrypting a hex-encoded string where the key is unknown. However, by leveraging the **Known Plaintext Attack (KPA)** methodology, this script derives the encryption key and recovers the original message (flag).

### 🛠️ Technical Concepts Applied
* **XOR Operation:** utilizing the property `A ^ B = C` implies `A ^ C = B`.
* **Known Plaintext Attack:** Using the standard flag format (`THM{`) to reverse-engineer the key.
* **Data Manipulation:** Hex-to-bytes conversion and ASCII character processing in Python.

## 💻 How It Works

1.  The script takes the encrypted hex string.
2.  It performs an XOR operation between the first few bytes of the ciphertext and the known prefix `THM{`.
3.  This reveals the start of the key.
4.  The script then iterates through the ciphertext using the derived key to decrypt the full flag.

## usage

To run the script, ensure you have Python installed:

```bash
python 
