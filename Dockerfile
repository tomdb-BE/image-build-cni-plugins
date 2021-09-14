ARG UBI_IMAGE
ARG GO_IMAGE

### Build the cni-plugins ###
FROM ${GO_IMAGE} as cni_plugins
ARG TAG
RUN git clone --depth=1 https://github.com/containernetworking/plugins.git $GOPATH/src/github.com/containernetworking/plugins \
    && cd $GOPATH/src/github.com/containernetworking/plugins \
    && git fetch --all --tags --prune \
    && git checkout tags/${TAG} -b ${TAG} \
    && sh -ex ./build_linux.sh -v \
    -gcflags=-trimpath=/go/src \
    -ldflags " \
        -X github.com/containernetworking/plugins/pkg/utils/buildversion.BuildVersion=${TAG} \
        -linkmode=external -extldflags \"-static -Wl,--fatal-warnings\" \
    "
WORKDIR $GOPATH/src/github.com/containernetworking/plugins
RUN go-assert-static.sh bin/* \
    && go-assert-boring.sh \
    bin/bandwidth \
    bin/bridge \
    bin/dhcp \
    bin/firewall \
    bin/host-device \
    bin/host-local \
    bin/ipvlan \
    bin/macvlan \
    bin/portmap \
    bin/ptp \
    bin/vlan \
    && mkdir -vp /opt/cni/bin \
    && install -D -s bin/* /opt/cni/bin

# Create image with the cni-plugins
FROM ${UBI_IMAGE}
COPY --from=cni_plugins /opt/cni/ /opt/cni/
WORKDIR /
COPY install-cnis.sh .
ENTRYPOINT ["./install-cnis.sh"]
