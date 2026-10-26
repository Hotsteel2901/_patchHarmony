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

## 设备定向构建（可选）

6.1 内核只在 vermagic 的 flag 段做严格比较：模块带 `__versions` 段时（`CONFIG_MODVERSIONS=y`
编出来的都有），`same_magic()` 会跳过第一段 release，只比
` SMP preempt mod_unload modversions aarch64`。所以一份 `android14-6.1` 构建能覆盖所有 6.1 设备，
不需要按 `uname -r` 编。

只有在碰到走完整字符串比较的内核（老内核、裁过 `CONFIG_MODVERSIONS` 的内核）时，
才用设备定向构建，把 kdir 的 `UTS_RELEASE` 钉成真机 release：

```sh
scripts/build-device.sh android14-6.1 6.1.141-android14-11-o-gxxxxxxxxxxx
```

CI：`.github/workflows/build.yml`（六个 KMI）、`.github/workflows/device.yml`（手动指定 release）。

已建档设备：

- OnePlus Ace 3 Pro（PJX110 / corvette，ColorOS 16 / 6.1.141 / android14-6.1）→ [docs/pjx110.md](docs/pjx110.md)

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
