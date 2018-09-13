# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )

inherit python-r1 toolchain-funcs

DESCRIPTION="Private sip for PyQt5 - Python extension module generator for C and C++ libraries"
HOMEPAGE="https://www.riverbankcomputing.com/software/sip/intro"
MY_PN=sip
MY_SIP="${PN%_sip}.sip"
MY_P="${MY_PN}-${PV}"
if [[ ${PV} == *9999 ]]; then
	inherit mercurial
	EHG_REPO_URI="https://www.riverbankcomputing.com/hg/sip"
elif [[ ${PV} == *_pre* ]]; then
	MY_DEV_P=${MY_P/_pre/.dev}
	SRC_URI="https://www.riverbankcomputing.com/static/Downloads/sip/${MY_DEV_P}.tar.gz"
	S=${WORKDIR}/${MY_P}
else
	SRC_URI="mirror://sourceforge/pyqt/${MY_P}.tar.gz"
fi

# Sub-slot based on SIP_API_MAJOR_NR from siplib/sip.h
SLOT="0/12"
LICENSE="|| ( GPL-2 GPL-3 SIP )"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="debug doc"

RDEPEND="${PYTHON_DEPS}"
DEPEND="${RDEPEND}"
if [[ ${PV} == *9999 ]]; then
	DEPEND+="sys-devel/bison sys-devel/flex"
fi

REQUIRED_USE="${PYTHON_REQUIRED_USE}"
if [[ ${PV} == *9999 ]]; then
	REQUIRED_USE+=" || ( $(python_gen_useflags 'python2*') )"
fi


S="${WORKDIR}/${MY_DEV_P:-${MY_P}}"

src_prepare() {
	if [[ ${PV} == *9999 ]]; then
		python_setup 'python2*'
		"${PYTHON}" build.py prepare || die
	fi

	# Sub-slot sanity check
	local sub_slot=${SLOT#*/}
	local sip_api_major_nr=$(sed -nre 's:^#define SIP_API_MAJOR_NR\s+([0-9]+):\1:p' siplib/sip.h || die)
	if [[ ${sub_slot} != ${sip_api_major_nr} ]]; then
		eerror
		eerror "Ebuild sub-slot (${sub_slot}) does not match SIP_API_MAJOR_NR (${sip_api_major_nr})"
		eerror "Please update SLOT variable as follows:"
		eerror "    SLOT=\"${SLOT%%/*}/${sip_api_major_nr}\""
		eerror
		die "sub-slot sanity check failed"
	fi

	default
}

src_configure() {
	configuration() {
		local myconf=(
			"${PYTHON}"
			"${S}"/configure.py
			--sip-module=PyQt5.sip
			--no-tools
			$(usex debug --debug '')
			AR="$(tc-getAR) cqs"
			CC="$(tc-getCC)"
			CFLAGS="${CFLAGS}"
			CFLAGS_RELEASE=
			CXX="$(tc-getCXX)"
			CXXFLAGS="${CXXFLAGS}"
			CXXFLAGS_RELEASE=
			LINK="$(tc-getCXX)"
			LINK_SHLIB="$(tc-getCXX)"
			LFLAGS="${LDFLAGS}"
			LFLAGS_RELEASE=
			RANLIB=
			STRIP=
		)
		echo "${myconf[@]}"
		"${myconf[@]}" || die
	}
	python_foreach_impl run_in_build_dir configuration
}

src_compile() {
	python_foreach_impl run_in_build_dir default
}

src_install() {
	installation() {
		emake DESTDIR="${D}" install
		#pushd "${D}$(python_get_sitedir)/${MY_SIP%.sip}" > /dev/null
		#mv sip.so "${MY_SIP}".so
		#mv sip.pyi "${MY_SIP}".pyi
		#popd > /dev/null
		python_optimize
	}
	python_foreach_impl run_in_build_dir installation

}
