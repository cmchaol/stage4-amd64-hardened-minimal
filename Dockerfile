
# This Dockerfile creates a gentoo stage4 container image. 
# It utilizes a multi-stage build and requires docker-17.05.0 or later. 
# It fetches a daily snapshot from the official 
# sources and verifies its checksum as well as its gpg signature.

# As gpg keyservers sometimes are unreliable, we use multiple gpg server pools
# to fetch the signing key.


FROM alpine:3.5 as builder

WORKDIR /tmp/gentoo

RUN apk add --no-cache  gnupg  tar  && U1="http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage4-amd64-hardened+minimal.txt" \
 && U2=$(wget -q -O-  | awk '/stage4/ {print $1}') \
 && U3="http://distfiles.gentoo.org/releases/amd64/autobuilds/" \
 && wget -q -c $U3$U2 $U3$U2.CONTENTS $U3$U2.DIGESTS.asc \
 && SIGNING_KEY="0xBB572E0E2D182910" \
 && gpg --keyserver hkps.pool.sks-keyservers.net --recv-keys ${SIGNING_KEY} \
 || gpg --keyserver keys.gnupg.net --recv-keys ${SIGNING_KEY} \                       
 || gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys ${SIGNING_KEY} \
 && gpg --verify *.DIGESTS.asc \
 && awk '/# SHA512 HASH/{getline; print}' *.DIGESTS.asc | sha512sum -c \
 && tar xjpf stage4*.bz2 --xattrs --numeric-owner \
 && sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf \
 && echo 'UTC' > etc/timezone \
 && rm stage4*


FROM scratch

WORKDIR /
COPY --from=builder /tmp/gentoo/ /
CMD ["/bin/bash"]
