FROM clearlinux:latest AS builder

ARG swupd_args

# Move to latest Clear Linux release
RUN swupd update --no-boot-update $swupd_args

# Install dnf
RUN swupd bundle-add package-utils curl
COPY dnf.conf /

# Install clean os-core bundle in target directory using the new os version
# Also install dnf
RUN source /usr/lib/os-release \
    && curl -f https://raw.githubusercontent.com/clearlinux/clr-bundles/$VERSION_ID/bundles/os-core | grep -v '^#' > ./os-core \
    && [[ -s ./os-core ]] \
    && mkdir /install_root \
    && dnf install --releasever=${VERSION_ID} \
       --config ./dnf.conf \
       --installroot /install_root \
       --assumeyes \
       $(< ./os-core) \
       rpm-python rpm \
       #dnf
       # dnf pulls in pygobject which takes ~400MB, not sure why it is needed
       # Install dnf components except pygobject
       dnf-bin dnf-python dnf-plugins-core gpgme iniparse libcomps libdnf librepo smartcols

# Bake VERSION_ID into dnf config
RUN source /usr/lib/os-release \
    && mkdir -p /install_root/etc/dnf/vars \
    && cp ./dnf.conf /install_root/etc/dnf/ \
    && echo ${VERSION_ID} > /install_root/etc/dnf/vars/releasever

FROM scratch
COPY --from=builder /install_root /
RUN clrtrust generate
CMD ["/bin/bash"]
