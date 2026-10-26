# droid_lkm

Out-of-tree kernel modules that provide missing namespace and IPC features
(`CONFIG_SYSVIPC`, `CONFIG_POSIX_MQUEUE`, `CONFIG_PID_NS`, `CONFIG_IPC_NS`)
for stock GKI kernels. It enables container runtimes like Droidspaces without
kernel recompilation or struct layout modifications, preserving vendor module
compatibility.

## Support Matrix

| Kernel Version | Android Version | Target |
| :--- | :--- | :--- |
| **5.10** | Android 12 | `android12-5.10` |
| **5.10** | Android 13 | `android13-5.10` |
| **5.15** | Android 13 | `android13-5.15` |
| **5.15** | Android 14 | `android14-5.15` |
| **6.1** | Android 14 | `android14-6.1` |
| **6.6** | Android 15 | `android15-6.6` |
| **6.12** | Android 16 | `android16-6.12` |
| **6.18** | Android 17 | `android17-6.18` |

## 设备定向构建（vermagic 钉死）

`insmod` 时内核会把 ko 的 `vermagic` 和运行中内核的逐字节比对，不同就 `-ENOEXEC`。
DDK 自带 kdir 是 `6.1.166-dirty`，所以通用构建在厂商机上通常报
`invalid module format`。设备构建只改 kdir 的 `UTS_RELEASE`，符号表和 CRC 不动：

```sh
scripts/build-device.sh android14-6.1 6.1.57-android14-11-o-gfc2eac419e6e
```

CI 走 `.github/workflows/device.yml`（手动触发，填 `uname -r`）。

已建档设备：

- OnePlus Ace 3 Pro（PJX110 / corvette，android14-6.1）→ [docs/pjx110.md](docs/pjx110.md)

## Contributors

- [XGH2333](https://github.com/XGH2333) (O3 CPU support)

## Credits

- [Droidspaces](https://github.com/ravindu644/Droidspaces-OSS) by ravindu644 — target container runtime
- [KMSDK](https://github.com/Dere3046/KMSDK) — SDK for library fetching and vendoring
- [KallRecon](https://github.com/Dere3046/KallRecon) — runtime kernel symbol resolution
- [Type_info](https://github.com/Dere3046/Type_info) — runtime struct layout reconstruction
- [KernCall](https://github.com/Dere3046/KernCall) — syscall table patching
- [HooKern](https://github.com/Dere3046/HooKern) — inline hook and kprobe engine

## License

GPL-2.0
