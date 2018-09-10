# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{4,5,6,7} )

inherit cmake-utils flag-o-matic python-r1 virtualx

DESCRIPTION="Python bindings for the Qt framework"
HOMEPAGE="https://wiki.qt.io/PySide2"
TARBALL="pyside-setup-everywhere-src-${PV}"
# See "sources/pyside2/PySide2/licensecomment.txt" for licensing details.
LICENSE="|| ( GPL-2 GPL-3+ LGPL-3 )"
SRC_URI="http://download.qt.io/official_releases/QtForPython/pyside2/PySide2-${PV}-src/${TARBALL}.tar.xz"
SLOT="2/2.0.0"
KEYWORDS="*"


IUSE="3d charts concurrent datavis3d declarative designer gui help location multimedia
	network opengl positioning printsupport script scripttools scxml sensors speech sql svg
	testlib webchannel webengine websockets widgets x11extras xmlpatterns"
# Excluded until fixed: webkit

# Note: 'testlib' for qttest used above due to name conflict with 'test' for running tests.
IUSE="${IUSE} test"

# The requirements below were extracted from the output of
# 'grep "set(.*_deps" "${S}"/PySide2/Qt*/CMakeLists.txt'
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	3d? ( concurrent )
	charts? ( widgets )
	datavis3d? ( gui 3d )
	declarative? ( gui network )
	designer? ( widgets )
	help? ( widgets )
	multimedia? ( gui network )
	opengl? ( x11extras widgets )
	printsupport? ( widgets )
	scripttools? ( gui script widgets )
	sql? ( widgets )
	svg? ( widgets )
	testlib? ( widgets )
	webengine? ( gui network webchannel widgets )
	websockets? ( network )
	widgets? ( gui )
	x11extras? ( gui )
"
# Excluded until fixed: webkit? ( gui network printsupport widgets )

# Minimum version of Qt required, derived from the CMakeLists.txt line:
#   find_package(Qt5 ${QT_PV} REQUIRED COMPONENTS Core)
QT_PV="5.9.0:5"

DEPEND="
	${PYTHON_DEPS}
	>=dev-python/shiboken2-${PV}:${SLOT}[${PYTHON_USEDEP}]
	>=dev-qt/qtcore-${QT_PV}
	>=dev-qt/qtxml-${QT_PV}
	3d? ( >=dev-qt/qt3d-${QT_PV} )
	charts? ( >=dev-qt/qtcharts-${QT_PV} )
	concurrent? ( >=dev-qt/qtconcurrent-${QT_PV} )
	datavis3d? ( >=dev-qt/qtdatavis3d-${QT_PV} )
	declarative? ( >=dev-qt/qtdeclarative-${QT_PV}[widgets?] )
	designer? ( >=dev-qt/designer-${QT_PV} )
	gui? ( >=dev-qt/qtgui-${QT_PV} )
	help? ( >=dev-qt/qthelp-${QT_PV} )
	location? ( >=dev-qt/qtlocation-${QT_PV} )
	multimedia? ( >=dev-qt/qtmultimedia-${QT_PV}[widgets?] )
	network? ( >=dev-qt/qtnetwork-${QT_PV} )
	opengl? ( >=dev-qt/qtopengl-${QT_PV} )
	positioning? ( >=dev-qt/qtpositioning-${QT_PV} )
	printsupport? ( >=dev-qt/qtprintsupport-${QT_PV} )
	script? ( >=dev-qt/qtscript-${QT_PV} )
	scxml? ( >=dev-qt/qtscxml-${QT_PV} )
	sensors? ( >=dev-qt/qtsensors-${QT_PV} )
	speech? ( >=dev-qt/qtspeech-${QT_PV} )
	sql? ( >=dev-qt/qtsql-${QT_PV} )
	svg? ( >=dev-qt/qtsvg-${QT_PV} )
	testlib? ( >=dev-qt/qttest-${QT_PV} )
	webchannel? ( >=dev-qt/qtwebchannel-${QT_PV} )
	webengine? ( >=dev-qt/qtwebengine-${QT_PV}[widgets] )
	websockets? ( >=dev-qt/qtwebsockets-${QT_PV} )
	widgets? ( >=dev-qt/qtwidgets-${QT_PV} )
	x11extras? ( >=dev-qt/qtx11extras-${QT_PV} )
	xmlpatterns? ( >=dev-qt/qtxmlpatterns-${QT_PV} )
	test? (
		x11-base/xorg-server[xvfb]
		x11-apps/xhost
	)
"
# Excluded until fixed: webkit? ( >=dev-qt/qtwebkit-${QT_PV}[printsupport] )

RDEPEND="${DEPEND}"

PATCHES=( "${FILESDIR}/pyside2-5.11.1-qtgui-make-gl-time-classes-optional.patch" )

S="${WORKDIR}/${TARBALL}/sources/${PN}"

src_prepare() {
	if use prefix; then
		cp "${FILESDIR}"/rpath.cmake . || die
		sed -i -e '1iinclude(rpath.cmake)' CMakeLists.txt || die
	fi

	# Excluded until fixed:
	#if use webkit ; then
	#	sed -e '/list(APPEND ALL_OPTIONAL_MODULES/ s/WebSockets/WebKit WebKitWidgets &/' \
	#		-i CMakeLists.txt || die
	#	sed -e '/value-type name="QWebDatabase"/ s/value-/object-/' \
	#		-e '/value-type name="QWebHistoryItem"/ s/value-/object-/' \
	#	-i PySide2/QtWebKitWidgets/typesystem_webkitwidgets.xml || die
	#fi


	cmake-utils_src_prepare
}

PYSIDE2_QT_PKGS="
Qt3DAnimation
Qt3DCore
Qt3DExtras
Qt3DInput
Qt3DLogic
Qt3DRender
QtCharts
QtConcurrent
QtCore
QtDataVisualization
QtGui
QtHelp
QtLocation
QtMultimedia
QtMultimediaWidgets
QtNetwork
QtOpenGL
QtPositioning
QtPrintSupport
QtQml
QtQuick
QtQuickWidgets
QtScript
QtScriptTools
QtScxml
QtSensors
QtSql
QtSvg
QtTest
QtTextToSpeech
QtUiTools
QtWebChannel
QtWebEngine
QtWebEngineCore
QtWebEngineWidgets
QtWebKit
QtWebKitWidgets
QtWebSockets
QtWidgets
QtX11Extras
QtXml
QtXmlPatterns
"

src_configure() {
	
	# See COLLECT_MODULE_IF_FOUND macros in CMakeLists.txt
	local mycmakeargs=(
		-DBUILD_TESTS=$(usex test)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Designer=$(usex !designer)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt53DAnimation=$(usex !3d)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt53DCore=$(usex !3d)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt53DExtras=$(usex !3d)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt53DInput=$(usex !3d)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt53DLogic=$(usex !3d)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt53DRender=$(usex !3d)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Charts=$(usex !charts)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Concurrent=$(usex !concurrent)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5DataVisualization=$(usex !datavis3d)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Gui=$(usex !gui)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Help=$(usex !help)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Location=$(usex !location)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Multimedia=$(usex !multimedia)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5MultimediaWidgets=$(usex !multimedia yes $(usex !widgets))
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Network=$(usex !network)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5OpenGL=$(usex !opengl)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Positioning=$(usex !positioning)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5PrintSupport=$(usex !printsupport)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Qml=$(usex !declarative)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Quick=$(usex !declarative)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5QuickWidgets=$(usex !declarative yes $(usex !widgets))
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Script=$(usex !script)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5ScriptTools=$(usex !scripttools)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Scxml=$(usex !scxml)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Sensors=$(usex !sensors)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Sql=$(usex !sql)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Svg=$(usex !svg)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Test=$(usex !testlib)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5TextToSpeech=$(usex !speech)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5UiTools=$(usex !designer)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5WebChannel=$(usex !webchannel)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5WebEngine=$(usex !webengine)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5WebEngineCore=$(usex !webengine)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5WebEngineWidgets=$(usex !webengine)
		# Excluded until fixed: -DCMAKE_DISABLE_FIND_PACKAGE_Qt5WebKit=$(usex !webkit)
		# Excluded until fixed: -DCMAKE_DISABLE_FIND_PACKAGE_Qt5WebKitWidgets=$(usex !webkit)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5WebSockets=$(usex !websockets)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Widgets=$(usex !widgets)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5X11Extras=$(usex !x11extras)
		-DCMAKE_DISABLE_FIND_PACKAGE_Qt5XmlPatterns=$(usex !xmlpatterns)
	)

	configuration() {
		local mycmakeargs=(
			"${mycmakeargs[@]}"
			-DPYTHON_EXECUTABLE="${PYTHON}"
		)
		cmake-utils_src_configure
	}
	python_foreach_impl configuration
}

src_compile() {
	python_foreach_impl cmake-utils_src_compile
}

src_test() {
	local -x PYTHONDONTWRITEBYTECODE
	if [ -z "${DISPLAY}" ] ; then
		ewarn "Running tests requires a running X server, selected by the DISPLAY variable, for Xvfb to connect to."
		elog "${P} tests not run without running X server and DISPLAY variable set!"
		elog "(But we're returning success anyway, since this is expected behavior.)"
		return 0
	fi
	_do_test() {
		 virtx cmake-utils_src_test
	}
	python_foreach_impl _do_test
}

src_install() {
	installation() {
		cmake-utils_src_install
		mv "${ED}"usr/$(get_libdir)/pkgconfig/${PN}{,-${EPYTHON}}.pc || die
	}
	python_foreach_impl installation
}
