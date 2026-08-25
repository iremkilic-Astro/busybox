# Paketleri söküp almak için geçici Debian aşaması
FROM debian:bookworm-slim AS extractor
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    nano \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Hedef dosya sistemi yapısını hazırla
RUN mkdir -p /rootfs/bin /rootfs/usr/bin /rootfs/usr/libexec /rootfs/lib /rootfs/lib64 /rootfs/etc/ssl/certs

# 1. Binary (Çalıştırılabilir) Dosyaları Kopyala
RUN cp /usr/bin/git /rootfs/usr/bin/git && \
    cp /usr/bin/curl /rootfs/usr/bin/curl && \
    cp /bin/nano /rootfs/bin/nano || cp /usr/bin/nano /rootfs/usr/bin/nano

# Git alt modülleri ve core araçlarını kopyala
RUN cp -r /usr/libexec/git-core /rootfs/usr/libexec/

# 2. İnternet ve SSL Sertifikalarını Kopyala (curl ve git için şart)
RUN cp -r /etc/ssl/certs/* /rootfs/etc/ssl/certs/

# 3. Gerekli Paylaşılan Kütüphaneleri (glibc bağımlılıkları) Dinamik Olarak Topla
RUN for bin in /usr/bin/git /usr/bin/curl /bin/nano /usr/bin/nano; do \
      if [ -f "$bin" ]; then \
        ldd "$bin" | grep -o '/lib[^ ]*' | while read -r lib; do \
          mkdir -p "/rootfs$(dirname "$lib")"; \
          cp "$lib" "/rootfs$lib" 2>/dev/null || true; \
        done; \
      fi; \
    done

# Nihai Saf Chog Linux İmajı
FROM busybox:glibc

# Toplanan tüm git, curl, nano ve kütüphaneleri sisteme enjekte et
COPY --from=extractor /rootfs/ /

# Karşılama mesajı ayarla
RUN echo 'echo -e "\e[1;35mWelcome to Chog Linux! (BusyBox + glibc + NetTools)\e[0m"' >> /etc/profile

# Varsayılan kabuk olarak kararlı BusyBox sh kullan
ENV SHELL=/bin/sh
ENTRYPOINT ["/bin/sh", "-l"]
