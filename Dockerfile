# Resmi glibc tabanlı BusyBox imajı
FROM busybox:glibc AS base

# Fish shell ve bağımlılıklarını indirmek için geçici Debian aşaması
FROM debian:bookworm-slim AS extractor
RUN apt-get update && apt-get install -y --no-install-recommends \
    fish \
    &> /dev/null

# Bağımlılıkların toplanacağı temiz dizin yapısı
RUN mkdir -p /rootfs/bin /rootfs/lib /rootfs/lib64 /rootfs/usr/share/fish /rootfs/etc

# Fish binary ve kütüphanelerini kopyala
RUN cp /usr/bin/fish /rootfs/bin/fish
RUN cp /lib/x86_64-linux-gnu/libpcre2-8.so.0* /rootfs/lib/ 2>/dev/null || true
RUN cp /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0* /rootfs/lib/ 2>/dev/null || true
RUN cp /lib/x86_64-linux-gnu/libncursesw.so.6* /rootfs/lib/ 2>/dev/null || true
RUN cp /usr/lib/x86_64-linux-gnu/libncursesw.so.6* /rootfs/lib/ 2>/dev/null || true
RUN cp -r /usr/share/fish /rootfs/usr/share/

# Chog Linux için özel Fish karşılama mesajı tanımla
RUN mkdir -p /rootfs/etc/fish
RUN echo 'function fish_greeting; echo (set_color purple)"Welcome to Chog Linux! (BusyBox + glibc + Fish)"(set_color normal); end' > /rootfs/etc/fish/config.fish

# Terminal ayarları için gerekli base terminfo tanımını al
RUN mkdir -p /rootfs/lib/terminfo/x
RUN cp /lib/terminfo/x/xterm-256color /rootfs/lib/terminfo/x/ 2>/dev/null || cp /usr/share/terminfo/x/xterm-256color /rootfs/lib/terminfo/x/

# Nihai Chog Linux imajı
FROM busybox:glibc

# Extractor aşamasından gelen Fish bileşenlerini kök dizine entegre et
COPY --from=extractor /rootfs/ /

# Çevre değişkenlerini ata
ENV TERM=xterm-256color
ENV SHELL=/bin/fish

# Varsayılan kabuğu Fish olarak ayarla
ENTRYPOINT ["/bin/fish"]
