# PhpWebStudy AMD64 .deb 包构建说明

## 快速构建

### 方法 1: 使用构建脚本（推荐）

```bash
cd /mnt/works/www_vue/016phpwebstudy
bash build-amd64-deb.sh
```

### 方法 2: 使用 yarn 命令

```bash
cd /mnt/works/www_vue/016phpwebstudy
yarn run build:amd64
```

### 方法 3: 手动执行完整流程

```bash
cd /mnt/works/www_vue/016phpwebstudy

# 1. 清理
rm -rf release dist/electron/main.js dist/electron/fork.js node_modules/node-pty/build/*

# 2. 编译源代码
cat scripts/args.esbuild.app-builder | xargs node_modules/.bin/esbuild

# 3. 打包
NODE_ENV=production ARCH=amd64 node electron/app-builder.js

# 4. 查看输出
ls -lh release/
```

## 输出位置

构建完成后，`.deb` 包位于：
```
release/PhpWebStudy-<version>.deb
```

## 安装方法

```bash
# 安装
sudo dpkg -i release/PhpWebStudy-*.deb

# 如果有依赖问题，执行
sudo apt-get install -f
```

## 卸载方法

```bash
sudo dpkg -r php-web-study
```

## 构建要求

- Node.js >= 18
- yarn 或 npm
- Linux x86_64 (AMD64) 系统
- 足够的磁盘空间（约 2GB）

## 常见问题

### Q: `npx: command not found`

**解决**: 使用 `node_modules/.bin/esbuild` 替代 `npx esbuild`

```bash
cat scripts/args.esbuild.app-builder | xargs node_modules/.bin/esbuild
```

### Q: 打包时提示缺少依赖

**解决**: 安装必要的构建工具

```bash
sudo apt-get install -y build-essential fakeroot libfakeroot
```

### Q: 生成的 .deb 包无法安装

**解决**: 检查系统架构是否匹配

```bash
dpkg --print-architecture  # 应该输出 amd64
```

## 当前版本的修复内容

本次构建包含以下修复：

1. ✅ **PHP 版本列表**: `apt search` → `apt list php*-fpm`
2. ✅ **PHP 扩展列表**: 修复版本号提取逻辑 (`php-fpm8.3` → `php8.3`)
3. ✅ **nginx 多版本**: `apt show nginx` → `apt show -a nginx`
4. ✅ **其他软件多版本**: apache/mysql/mariadb/postgresql/redis/caddy/memcached/pure-ftpd 全部添加 `-a` 参数

## 版本更新后重新打包

如果源代码有更新，只需重新执行构建脚本：

```bash
cd /mnt/works/www_vue/016phpwebstudy
bash build-amd64-deb.sh
```

新的 `.deb` 包会覆盖旧版本。
