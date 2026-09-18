# VANGUARD
# VANGUARD

### Web Security Assessment Toolkit

VANGUARD is a simple Bash-based web security assessment and reconnaissance tool. It combines common security tools into one terminal-based program to make basic security testing easier.

## Features

* DNS information gathering
* Port and service scanning using Nmap
* HTTP/HTTPS analysis
* Security header checking
* Basic technology detection
* TLS certificate information
* `robots.txt` and `sitemap.xml` checking
* Automatic report generation
* Simple and professional terminal interface

## Requirements

VANGUARD requires:

* Bash
* Nmap
* cURL
* Dig
* OpenSSL

For Kali Linux / Ubuntu / Debian:

```bash
sudo apt update
sudo apt install nmap curl dnsutils openssl
```

## Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/vanguard.git
cd vanguard
```

Give the script permission to run:

```bash
chmod +x vanguard.sh
```

Run VANGUARD:

```bash
./vanguard.sh
```

You can also run it using:

```bash
bash vanguard.sh
```

## How It Works

Enter the domain or IP address when asked:

```text
Target domain/IP: example.com
```

VANGUARD then performs DNS, port, HTTP, security header, TLS, and web metadata checks and displays the results in the terminal.

## Reports

Results are automatically saved in the `reports` folder.

Example:

```text
reports/
└── example.com_YYYYMMDD_HHMMSS/
    ├── assessment_report.txt
    ├── nmap.txt
    ├── dns.txt
    ├── http.txt
    ├── security_headers.txt
    └── tls.txt
```

## Purpose

VANGUARD is mainly intended for cybersecurity learning, penetration testing practice, security labs, and authorized security assessments.

## Disclaimer

Use VANGUARD only on systems or domains that you own or have permission to test. The developer is not responsible for unauthorized or illegal use of this tool.
