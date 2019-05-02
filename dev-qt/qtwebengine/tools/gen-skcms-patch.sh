SKCMS_GIT_REPO="https://skia.googlesource.com/skcms"
SKCMS_FILES="skcms.cc skcms.gni skcms.h skcms_internal.h src/Transform_inl.h"
QTWE_SKCMS_SUBDIR="src/3rdparty/chromium/third_party/skia/third_party/skcms"

die() {
	printf -- '%s\n' "${@}"
	exit 1
}

qtwe_skcms_patch-ebuild_unpack() {
	export QTWE_EBUILD_DIR="$(pwd)"
	export QTWE_EBUILD="${1##*/}"
	ebuild "${QTWE_EBUILD}" digest clean unpack || die "Command 'ebuild ${QTWE_EBUILD} digest clean unpack' failed."

	eval $(emerge --info | grep '^PORTAGE_TMPDIR=')
	export QTWE_BUILDDIR="${PORTAGE_TMPDIR}/portage/dev-qt/${QTWE_EBUILD%.ebuild}"

	export WORKDIR="${QTWE_BUILDDIR}/work"
	export T="${QTWE_BUILDDIR}/temp"

	S="$(echo "${WORKDIR}"/qtwebengine*)"
	[ "${S}" != "${WORKDIR}/qtwebengine*" ] || die "Could not find src dir in '${WORKDIR}'."
	export S

	cd "${S}/${QTWE_SKCMS_SUBDIR}" || die "Could not change to skcms subdir '${S}/${QTWE_SKCMS_SUBDIR}'."
	git init . || die "Could not init git repo for '${S}/${QTWE_SKCMS_SUBDIR}'."
	git add .
	git commit -m "Old"
}

qtwe_skcms_patch-fetch_repo() {
	cd "${T}"
	git clone "${SKCMS_GIT_REPO}" skcms || die "Could not clone skcms repo from '${SKCMS_GIT_REPO}' to '${T}/skcms'."
	cd skcms
	export SKCMS_GIT_COMMIT="$(git log | awk 'NR==1 { print $2; };')"
}

qtwe_skcms_patch-copy_files() {

	cd "${S}/${QTWE_SKCMS_SUBDIR}" || die "Could not change to skcms subdir '${S}/${QTWE_SKCMS_SUBDIR}'."
	for myfile in ${SKCMS_FILES}; do
		cp -vf "${T}/skcms/${myfile}" "${myfile}"
	done
	echo "${SKCMS_GIT_COMMIT}" > version.sha1
}

qtwe_skcms_patch-generate_patch() {

	cd "${S}/${QTWE_SKCMS_SUBDIR}" || die "Could not change to skcms subdir '${S}/${QTWE_SKCMS_SUBDIR}'."
	export QTWE_SKCMS_PATCH="${QTWE_EBUILD%.ebuild}-skcms-update-${SKCMS_GIT_COMMIT}.patch"

	[ -d "${QTWE_EBUILD_DIR}/files" ] || mkdir -p "${QTWE_EBUILD_DIR}/files" || die "Could not create files/ dir under '${QTWE_EBUILD_DIR}'."
	git diff -p  --src-prefix="a/${QTWE_SKCMS_SUBDIR}/" --dst-prefix="b/${QTWE_SKCMS_SUBDIR}/" > "${QTWE_EBUILD_DIR}/files/${QTWE_SKCMS_PATCH}" || die "Could not init git repo for '${S}/${QTWE_SKCMS_SUBDIR}'."
}

qtwe_skcms_patch-update_ebuild() {
	if grep -q '^# Update skia skcms' "${QTWE_EBUILD_DIR}/${QTWE_EBUILD}" ; then
		sed -e 's|\(PATCHES+=( "${FILESDIR}/\).*skcms-update.*.patch|\1'"${QTWE_SKCMS_PATCH}"'|' \
			-i "${QTWE_EBUILD_DIR}/${QTWE_EBUILD}"
	else
		sed -e '/^src_prepare()/i\# Update skia skcms to fix build errors.\nPATCHES+=( "${FILESDIR}/'"${QTWE_SKCMS_PATCH}"'" )\n\n' \
			-i "${QTWE_EBUILD_DIR}/${QTWE_EBUILD}"
	fi
}

qtwe_skcms_patch() {
	qtwe_skcms_patch-ebuild_unpack "${1}"
	qtwe_skcms_patch-fetch_repo
	qtwe_skcms_patch-copy_files
	qtwe_skcms_patch-generate_patch
	qtwe_skcms_patch-update_ebuild
}

[ -f "tools/${0##*/}" ] || die "Please run from qtwebengine cat/pkg root directory."
[ $# -gt 0 ] || die "Please provide a list of ebuilds to update."

for myqtwe in "${@}" ; do
	[ -f "${myqtwe}" ] || die "Ebuild '${myqtwe}' does not exist."
	qtwe_skcms_patch "${myqtwe}"
done




