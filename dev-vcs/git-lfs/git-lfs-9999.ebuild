# Copyright 2017-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGO_PN=github.com/git-lfs/git-lfs
# Update the ID as it's included in each build.
COMMIT_ID="77deabdf9a18f8a07ecfd3e0f4aa572ffbbab8d4"

inherit go-module

DESCRIPTION="Command line extension and specification for managing large files with git"
HOMEPAGE="
	https://git-lfs.com
	https://github.com/git-lfs/git-lfs
"

if [[ "${PV}" = 9999* ]]; then
	EGIT_REPO_URI="https://${EGO_PN}"
	inherit git-r3
else
	SRC_URI="https://${EGO_PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	# Add the manually vendored tarball.
	# Compress the tarball with: xz -9kT0 --memlimit-decompress=256M
	SRC_URI+=" https://files.holgersson.xyz/gentoo/distfiles/golang-pkg-deps/${P}-deps.tar.xz"
	KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv ~x86 ~amd64-linux ~x86-linux"
fi

LICENSE="Apache-2.0 BSD BSD-2 BSD-4 ISC MIT"
SLOT="0"
IUSE="doc test"

BDEPEND="
	doc? ( dev-ruby/asciidoctor )
"
RDEPEND="dev-vcs/git"

RESTRICT+=" !test? ( test )"

DOCS=(
	CHANGELOG.md
	CODE-OF-CONDUCT.md
	CONTRIBUTING.md
	README.md
	SECURITY.md
)

src_compile() {
	export CGO_ENABLED=0

	# Flags -w, -s: Omit debugging information to reduce binary size,
	# see https://golang.org/cmd/link/.
	local mygobuildargs=(
		-ldflags="-X ${EGO_PN}/config.GitCommit=${COMMIT_ID} -s -w"
		-gcflags=" "
		-trimpath
		-v -work -x
	)
	go build "${mygobuildargs[@]}" -o git-lfs git-lfs.go || die

	if use doc; then
		for doc in docs/man/*adoc;
			do asciidoctor -b manpage ${doc} || die "man building failed"
		done
	fi
}

src_install() {
	dobin git-lfs
	einstalldocs
	use doc && doman docs/man/*.1
}

src_test() {
	local mygotestargs=(
		-ldflags="-X ${EGO_PN}/config.GitCommit=${COMMIT_ID}"
	)
	go test "${mygotestargs[@]}" ./... || die
}

pkg_postinst () {
	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		elog ""
		elog "Run 'git lfs install' once for each user account manually."
		elog "For more details see https://bugs.gentoo.org/show_bug.cgi?id=733372."
	fi
}
