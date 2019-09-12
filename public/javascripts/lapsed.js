var lapsed =
webpackJsonp_name_([0],{

/***/ 0:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var ReactDOM = __webpack_require__(1);

	var _require = __webpack_require__(2),
	    BrowserRouter = _require.BrowserRouter;

	var Doc = __webpack_require__(51);

	initData = JSON.parse(initData);
	userData = JSON.parse(userData);

	ReactDOM.hydrate(React.createElement(
	    BrowserRouter,
	    null,
	    React.createElement(Doc, { initData: initData, userData: userData })
	), document.getElementById('doc'));

/***/ }),

/***/ 51:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(6);

	var Menu = __webpack_require__(52);

	var Docs = __webpack_require__(159);

	var LapseDokument = __webpack_require__(239);
	var LasteRegister = __webpack_require__(264);

	var VanemDokument = __webpack_require__(266);
	var VanemateRegister = __webpack_require__(271);

	var ArvedeRegister = __webpack_require__(273);

	var SmkRegister = __webpack_require__(275);

	var SorderideRegister = __webpack_require__(277);

	var AsutusRegister = __webpack_require__(279),
	    AsutusDocument = __webpack_require__(281);

	var _require = __webpack_require__(2),
	    Route = _require.Route,
	    withRouter = _require.withRouter;

	var _require2 = __webpack_require__(91),
	    StyleRoot = _require2.StyleRoot;

	var MODULE = 'Lapsed';

	var App = function (_React$Component) {
	    _inherits(App, _React$Component);

	    function App(props) {
	        _classCallCheck(this, App);

	        var _this = _possibleConstructorReturn(this, (App.__proto__ || Object.getPrototypeOf(App)).call(this, props));

	        _this.prepareParamsForToolbar = _this.prepareParamsForToolbar.bind(_this);
	        _this.state = {
	            userData: _this.props.userData
	        };
	        _this.componets = {};
	        _this.prepareComponents(_this.componets);
	        return _this;
	    }

	    _createClass(App, [{
	        key: 'render',
	        value: function render() {
	            var _this2 = this;

	            var context = {};
	            var btnParams = this.prepareParamsForToolbar();

	            return React.createElement(
	                StyleRoot,
	                null,
	                React.createElement(Route, { path: '/lapsed',
	                    render: function render() {
	                        return React.createElement(Menu, { params: btnParams, userData: _this2.state.userData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed',
	                    render: function render(props) {
	                        return React.createElement(Docs, { history: props.history, userData: _this2.props.userData, initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/docs',
	                    render: function render(props) {
	                        return React.createElement(Docs, { history: props.history, userData: _this2.props.userData, initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/laps',
	                    render: function render(props) {
	                        return React.createElement(LasteRegister, { history: props.history, userData: _this2.props.userData, initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/laps/:docId', component: LapseDokument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/vanem',
	                    render: function render(props) {
	                        return React.createElement(VanemateRegister, { history: props.history, userData: _this2.props.userData, initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/vanem/:docId', component: VanemDokument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/arv',
	                    render: function render(props) {
	                        return React.createElement(ArvedeRegister, { history: props.history, userData: _this2.props.userData, initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/smk',
	                    render: function render(props) {
	                        return React.createElement(SmkRegister, { history: props.history, userData: _this2.props.userData, initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/sorder',
	                    render: function render(props) {
	                        return React.createElement(SorderideRegister, { history: props.history, userData: _this2.props.userData, initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/asutused/:docId', component: AsutusDocument, module: MODULE }),
	                React.createElement(Route, { exact: true, path: '/lapsed/asutused',
	                    render: function render(props) {
	                        return React.createElement(AsutusRegister, { history: props.history, userData: _this2.props.userData, initData: _this2.props.initData, module: MODULE });
	                    } })
	            );
	        }
	    }, {
	        key: 'prepareParamsForToolbar',
	        value: function prepareParamsForToolbar() {
	            return {
	                btnStart: {
	                    show: true
	                },
	                btnLogin: {
	                    show: true,
	                    disabled: false
	                },
	                btnAccount: {
	                    show: true,
	                    disabled: false
	                }

	            };
	        }
	    }, {
	        key: 'prepareComponents',
	        value: function prepareComponents(components) {
	            return components['LapseDocument'] = function (props) {
	                var LapseDocument = __webpack_require__(239);
	                return React.createElement(LapseDocument, props);
	            };
	        }
	    }]);

	    return App;
	}(React.Component);

	module.exports = App;

/***/ }),

/***/ 239:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(7);
	var React = __webpack_require__(6);

	var DocumentTemplate = __webpack_require__(240),
	    InputText = __webpack_require__(254),
	    InputNumber = __webpack_require__(256),
	    Select = __webpack_require__(258),
	    TextArea = __webpack_require__(260),
	    DataGrid = __webpack_require__(161),
	    relatedDocuments = __webpack_require__(262),
	    ModalPage = __webpack_require__(235),
	    styles = __webpack_require__(263);

	var LIBDOK = 'LAPS',
	    LIBRARIES = ['asutused'];

	var now = new Date();

	var Laps = function (_React$PureComponent) {
	    _inherits(Laps, _React$PureComponent);

	    function Laps(props) {
	        _classCallCheck(this, Laps);

	        var _this = _possibleConstructorReturn(this, (Laps.__proto__ || Object.getPrototypeOf(Laps)).call(this, props));

	        _this.state = {
	            loadedData: false,
	            docId: props.docId ? props.docId : Number(props.match.params.docId)
	        };

	        _this.renderer = _this.renderer.bind(_this);
	        _this.handlePageClick = _this.handlePageClick.bind(_this);
	        _this.handleTeenusteGridBtnClick = _this.handleTeenusteGridBtnClick.bind(_this);
	        _this.handleVanemadGridBtnClick = _this.handleVanemadGridBtnClick.bind(_this);

	        _this.pages = [{ pageName: 'Lapse kaart', docTypeId: 'LAPS' }, { pageName: 'Arved', handlePageClick: _this.handlePageClick, docTypeId: 'ARV' }, { pageName: 'Maksekoraldused', handlePageClick: _this.handlePageClick, docTypeId: 'SMK' }, { pageName: 'Kassaorderid', handlePageClick: _this.handlePageClick, docTypeId: 'SORDER' }];
	        _this.requiredFields = [{
	            name: 'isikukood',
	            type: 'C'
	        }, { name: 'nimi', type: 'C' }];
	        return _this;
	    }

	    _createClass(Laps, [{
	        key: 'render',
	        value: function render() {
	            var initData = this.props.initData ? this.props.initData : {};

	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'LAPS',
	                requiredFields: this.requiredFields,
	                userData: this.props.userData,
	                initData: initData,
	                libs: LIBRARIES,
	                pages: this.pages,
	                renderer: this.renderer,
	                createGridRow: this.createGridRow,
	                gridValidator: this.gridValidateFields,
	                focusElement: 'input-isikukood'
	            });
	        }

	        /**
	         *Вернет кастомные компоненты документа
	         */

	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            var bpm = self.docData && self.docData.bpm ? self.docData.bpm : [],
	                isEditMode = self.state.edited,
	                gridVanemadData = self.docData.vanemad,
	                gridVanemadColumns = self.docData.gridConfig,
	                gridTeenusteData = self.docData.teenused,
	                gridTeenusteColumns = self.docData.gridTeenusteConfig;

	            // формируем зависимости
	            if (self.docData.relations) {
	                relatedDocuments(self);
	            }

	            var doc = this.refs['document'];
	            var libs = doc ? doc.libs : {};

	            return React.createElement(
	                'div',
	                null,
	                React.createElement(
	                    'div',
	                    { style: styles.doc },
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(
	                            'div',
	                            { style: styles.docColumn },
	                            React.createElement(InputText, { ref: 'input-isikukood',
	                                title: 'Isikukood:',
	                                name: 'isikukood',
	                                value: self.docData.isikukood || '',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange }),
	                            React.createElement(InputText, { title: 'Nimi:',
	                                name: 'nimi',
	                                value: self.docData.nimi || '',
	                                ref: 'input-nimi',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange }),
	                            React.createElement(InputText, { title: 'Viitenumber:',
	                                name: 'viitenumber',
	                                value: self.docData.viitenumber || '',
	                                ref: 'input-viitenumber',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docColumn },
	                            React.createElement(InputText, { ref: 'input-jaak',
	                                title: 'J\xE4\xE4k:',
	                                name: 'jaak',
	                                value: self.docData.jaak || '',
	                                readOnly: true
	                            })
	                        )
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(TextArea, { title: 'M\xE4rkused',
	                            name: 'muud',
	                            ref: 'textarea-muud',
	                            onChange: self.handleInputChange,
	                            value: self.docData.muud || '',
	                            readOnly: !isEditMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(
	                            'label',
	                            { ref: 'label' },
	                            'Vanemad'
	                        )
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(DataGrid, { source: 'vanemad',
	                            gridData: gridVanemadData,
	                            gridColumns: gridVanemadColumns,
	                            showToolBar: !isEditMode,
	                            handleGridBtnClick: this.handleVanemadGridBtnClick,
	                            readOnly: !isEditMode,
	                            style: styles.grid.headerTable,
	                            ref: 'vanemad-data-grid' })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(
	                            'label',
	                            { ref: 'label' },
	                            'Teenused'
	                        )
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(DataGrid, { source: 'teenused',
	                            gridData: gridTeenusteData,
	                            gridColumns: gridTeenusteColumns,
	                            showToolBar: !isEditMode,
	                            handleGridBtnClick: this.handleTeenusteGridBtnClick,
	                            readOnly: !isEditMode,
	                            style: styles.grid.headerTable,
	                            ref: 'teenuste-data-grid' })
	                    )
	                )
	            );
	        }
	    }, {
	        key: 'handlePageClick',
	        value: function handlePageClick(pageDocTypeId) {
	            //        document.location.href = `/lapsed/${pageDocTypeId}/`;//@todo Обновить
	            this.props.history.push('/lapsed/' + pageDocTypeId);
	        }
	    }, {
	        key: 'handleTeenusteGridBtnClick',
	        value: function handleTeenusteGridBtnClick(btnName) {
	            console.log('teenuste handleGridBtnClick', btnName);
	            this.props.history.push('/lapsed/teenused/' + id);
	        }
	    }, {
	        key: 'handleVanemadGridBtnClick',
	        value: function handleVanemadGridBtnClick(btnName) {
	            console.log('vanemad handleGridBtnClick', btnName);
	            var id = 0;
	            this.props.history.push('/lapsed/vanemad/' + id);
	        }
	    }]);

	    return Laps;
	}(React.PureComponent);

	Laps.propTypes = {
	    docId: PropTypes.number,
	    initData: PropTypes.object,
	    userData: PropTypes.object
	};

	Laps.defaultProps = {
	    params: { docId: 0 },
	    initData: {},
	    userData: {}
	};

	module.exports = Laps;

/***/ }),

/***/ 263:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    docRow: {
	        display: 'flex',
	        flexDirection: 'row'
	        /*
	                border: '1px solid blue'
	        */
	    },
	    docColumn: {
	        display: 'flex',
	        flexDirection: 'column',
	        /*
	                border: '1px solid yellow',
	        */
	        width: '50%'
	    },
	    doc: {
	        display: 'flex',
	        flexDirection: 'column'
	        /*
	                border: '1px solid brown'
	        */
	    },

	    grid: {
	        mainTable: {
	            width: '100%'
	        },
	        headerTable: {
	            width: '100%'
	        },

	        gridContainer: {
	            width: '100%'
	        }

	    },

	    gridRow: {
	        /*
	                border: '1px solid black',
	        */
	        backgroundColor: 'white',
	        position: 'relative',
	        margin: '10% 30% 10% 30%',
	        width: 'auto',
	        opacity: '1',
	        top: '100px'
	    }

	};

/***/ }),

/***/ 264:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(6);
	var DocumentRegister = __webpack_require__(160);
	var styles = __webpack_require__(265);
	var DOC_TYPE_ID = 'LAPS';

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        return _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));
	    }

	    _createClass(Documents, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentRegister, { initData: this.props.initData,
	                userData: this.props.userData,
	                history: this.props.history ? this.props.history : null,
	                module: this.props.module,
	                ref: 'register',
	                docTypeId: DOC_TYPE_ID,
	                style: styles,
	                render: this.renderer });
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer() {
	            return React.createElement(
	                'div',
	                null,
	                'Laste register special render'
	            );
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 265:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    grid: {
	        mainTable: {
	            width: '100%'
	        },
	        headerTable: {
	            width: '100%'
	        },

	        gridContainer: {
	            width: '100%'
	        }

	    }
	};

/***/ }),

/***/ 266:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(7);
	var React = __webpack_require__(6);

	var DocumentTemplate = __webpack_require__(240),
	    InputText = __webpack_require__(254),
	    Select = __webpack_require__(258),
	    ButtonEdit = __webpack_require__(164),
	    SelectData = __webpack_require__(267),
	    TextArea = __webpack_require__(260),
	    DataGrid = __webpack_require__(161),
	    ModalPage = __webpack_require__(235),
	    styles = __webpack_require__(270);

	var LIBDOK = 'VANEM',
	    LIBRARIES = [];

	var now = new Date();

	var Vanem = function (_React$PureComponent) {
	    _inherits(Vanem, _React$PureComponent);

	    function Vanem(props) {
	        _classCallCheck(this, Vanem);

	        var _this = _possibleConstructorReturn(this, (Vanem.__proto__ || Object.getPrototypeOf(Vanem)).call(this, props));

	        _this.state = {
	            loadedData: false,
	            docId: props.docId ? props.docId : Number(props.match.params.docId)
	        };

	        _this.renderer = _this.renderer.bind(_this);
	        _this.handlePageClick = _this.handlePageClick.bind(_this);
	        _this.handleLasteGridBtnClick = _this.handleLasteGridBtnClick.bind(_this);
	        _this.btnEditAsutusClick = _this.btnEditAsutusClick.bind(_this);

	        _this.pages = [{ pageName: 'Vanem kaart', docTypeId: 'VANEM' }, { pageName: 'Arved', handlePageClick: _this.handlePageClick, docTypeId: 'ARV' }, { pageName: 'Maksekoraldused', handlePageClick: _this.handlePageClick, docTypeId: 'SMK' }, { pageName: 'Kassaorderid', handlePageClick: _this.handlePageClick, docTypeId: 'SORDER' }];
	        _this.requiredFields = [{
	            name: 'asutusid',
	            type: 'I'
	        }, { name: 'parentid', type: 'I' }];
	        return _this;
	    }

	    _createClass(Vanem, [{
	        key: 'render',
	        value: function render() {
	            var initData = this.props.initData ? this.props.initData : {};

	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'VANEM',
	                requiredFields: this.requiredFields,
	                userData: this.props.userData,
	                initData: initData,
	                libs: LIBRARIES,
	                pages: this.pages,
	                renderer: this.renderer,
	                handleGridBtnClick: this.handleLasteGridBtnClick,
	                focusElement: 'input-isikukood'
	            });
	        }

	        /**
	         *Вернет кастомные компоненты документа
	         */

	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            var isEditMode = self.state.edited,
	                gridLasteData = self.docData.lapsed,
	                gridLasteColumns = self.docData.gridConfig;

	            // формируем зависимости
	            if (self.docData.relations) {
	                relatedDocuments(self);
	            }

	            var asutusGrid = [{ id: "id", name: "id", width: "50px", show: false }, { id: "regkood", name: "Isikukood", width: "100px" }, { id: "nimetus", name: "Nimi", width: "100px" }];

	            return React.createElement(
	                'div',
	                null,
	                React.createElement(
	                    'div',
	                    { style: styles.doc },
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(
	                            'div',
	                            { style: styles.docColumn },
	                            React.createElement(
	                                'div',
	                                { style: styles.docRow },
	                                React.createElement(SelectData, { title: 'Vanem:',
	                                    name: 'asutusid',
	                                    libName: 'asutused',
	                                    sqlFields: ['nimetus', 'regkood'],
	                                    data: [],
	                                    config: asutusGrid,
	                                    value: self.docData.asutusid || 0,
	                                    defaultValue: self.docData.vanem_nimi,
	                                    boundToGrid: 'nimetus',
	                                    boundToData: 'vanem_nimi',
	                                    ref: 'select-asutusid',
	                                    btnDelete: false,
	                                    onChange: self.handleInputChange,
	                                    readOnly: !isEditMode }),
	                                React.createElement(ButtonEdit, {
	                                    ref: 'btnEdit',
	                                    onClick: this.btnEditAsutusClick,
	                                    show: !isEditMode,
	                                    disabled: false
	                                })
	                            ),
	                            React.createElement(InputText, { title: 'Sugulus:',
	                                name: 'suhtumine',
	                                value: self.docData.suhtumine || '',
	                                ref: 'input-suhtumine',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange }),
	                            React.createElement(Select, { title: 'Arveldus:',
	                                name: 'arved',
	                                data: [{ name: 'Jah' }, { name: 'Ei' }],
	                                value: self.docData.arved || 'Ei',
	                                collId: 'name',
	                                defaultValue: self.docData.arved,
	                                ref: 'select-arved',
	                                btnDelete: false,
	                                onChange: self.handleInputChange,
	                                readOnly: !isEditMode })
	                        )
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(TextArea, { title: 'M\xE4rkused',
	                            name: 'muud',
	                            ref: 'textarea-muud',
	                            onChange: self.handleInputChange,
	                            value: self.docData.muud || '',
	                            readOnly: !isEditMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(
	                            'label',
	                            { ref: 'label' },
	                            'Lapsed'
	                        )
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(DataGrid, { source: 'lapsed',
	                            gridData: gridLasteData,
	                            gridColumns: gridLasteColumns,
	                            showToolBar: !isEditMode,
	                            handleGridBtnClick: self.handleGridBtnClick,
	                            readOnly: !isEditMode,
	                            style: styles.grid.headerTable,
	                            ref: 'laspsed-data-grid' })
	                    )
	                )
	            );
	        }
	    }, {
	        key: 'handlePageClick',
	        value: function handlePageClick(pageDocTypeId) {
	            //        document.location.href = `/lapsed/${pageDocTypeId}/`;//@todo Обновить
	            this.props.history.push('/lapsed/' + pageDocTypeId);
	        }
	    }, {
	        key: 'handleLasteGridBtnClick',
	        value: function handleLasteGridBtnClick(btnName, id) {

	            switch (btnName) {
	                case "edit":
	                    this.props.history.push('/lapsed/laps/' + id);

	                    break;
	                case "add":
	                    console.log('btnAdd clicked');
	                    this.props.history.push('/lapsed/laps/0');
	                    break;
	                case "delete":
	                    console.log('btnDelete clicked');
	                    break;
	                default:
	                    console.log('Vigane click');
	            }
	        }

	        // обработчик события клиска на кнопке редактирования контр-агента

	    }, {
	        key: 'btnEditAsutusClick',
	        value: function btnEditAsutusClick() {
	            var docAsutusId = this.refs['document'].docData.asutusid;

	            // осуществит переход на карточку контр-агента
	            this.props.history.push('/lapsed/asutused/' + docAsutusId);
	        }
	    }]);

	    return Vanem;
	}(React.PureComponent);

	Vanem.propTypes = {
	    docId: PropTypes.number,
	    initData: PropTypes.object,
	    userData: PropTypes.object
	};

	Vanem.defaultProps = {
	    params: { docId: 0 },
	    initData: {},
	    userData: {}
	};

	module.exports = Vanem;

/***/ }),

/***/ 267:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(7);
	var getDataByFilter = __webpack_require__(268);
	var fetchData = __webpack_require__(53);

	var React = __webpack_require__(6),
	    styles = __webpack_require__(269),
	    DataGrid = __webpack_require__(161),
	    Button = __webpack_require__(84),
	    InputText = __webpack_require__(254),
	    ModalPage = __webpack_require__(235);

	var SelectData = function (_React$PureComponent) {
	    _inherits(SelectData, _React$PureComponent);

	    function SelectData(props) {
	        _classCallCheck(this, SelectData);

	        var _this = _possibleConstructorReturn(this, (SelectData.__proto__ || Object.getPrototypeOf(SelectData)).call(this, props));

	        _this.state = {
	            value: props.value, /* возвращаемое значение, например id*/
	            fieldValue: props.defaultValue, /*видимое значение, например kood или name по указанному в collId */
	            readOnly: props.readOnly,
	            disabled: props.disabled,
	            edited: props.edited,
	            gridData: [],
	            gridConfig: props.config,
	            gridActiveRow: 0,
	            show: _this.props.show
	        };
	        //        this.onChange = this.onChange.bind(this);
	        _this.handleInputChange = _this.handleInputChange.bind(_this);
	        _this.handleGridClick = _this.handleGridClick.bind(_this);
	        _this.modalPageClick = _this.modalPageClick.bind(_this);
	        _this.loadLibs = _this.loadLibs.bind(_this);
	        return _this;
	    }

	    _createClass(SelectData, [{
	        key: 'componentWillReceiveProps',
	        value: function componentWillReceiveProps(nextProps) {

	            this.setState({
	                value: nextProps.value,
	                fieldValue: nextProps.defaultValue,
	                readOnly: nextProps.readOnly,
	                show: nextProps.show
	            });
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var _this2 = this;

	            var isEditeMode = !this.state.readOnly,
	                btnStyle = Object.assign({}, styles.button, { display: isEditeMode ? 'inline' : 'none' });

	            return React.createElement(
	                'div',
	                { style: styles.wrapper },
	                React.createElement(InputText, { ref: 'input',
	                    title: this.props.title,
	                    name: this.props.name,
	                    value: this.state.fieldValue,
	                    readOnly: !isEditeMode,
	                    onChange: this.handleInputChange }),
	                React.createElement(Button, { value: 'v',
	                    ref: 'btnShow',
	                    style: btnStyle,
	                    onClick: function onClick(e) {
	                        return _this2.handleClick(e);
	                    } }),
	                this.state.show ? this.modalPage() : null
	            );
	        }
	    }, {
	        key: 'handleClick',
	        value: function handleClick(e) {
	            this.setState({
	                show: true
	            });
	        }
	    }, {
	        key: 'modalPage',
	        value: function modalPage() {
	            var modalObjects = ['btnOk', 'btnCancel'];

	            return React.createElement(
	                'div',
	                null,
	                React.createElement(
	                    ModalPage,
	                    {
	                        modalObjects: modalObjects,
	                        ref: 'modalpage-grid',
	                        show: true,
	                        modalPageBtnClick: this.modalPageClick,
	                        modalPageName: 'Vali rea' },
	                    React.createElement(
	                        'div',
	                        { ref: 'grid-row-container' },
	                        React.createElement(InputText, { ref: 'input-filter',
	                            title: 'Otsingu parametrid',
	                            name: 'gridFilter',
	                            value: this.state.fieldValue,
	                            readOnly: false,
	                            onChange: this.handleInputChange }),
	                        React.createElement(DataGrid, { gridData: this.state.gridData,
	                            gridColumns: this.state.gridConfig,
	                            onClick: this.handleGridClick,
	                            ref: 'data-grid' })
	                    )
	                )
	            );
	        }

	        // обработчик события измения значения в текстовом (поисковом) поле

	    }, {
	        key: 'handleInputChange',
	        value: function handleInputChange(name, value) {
	            this.setState({ fieldValue: value, show: true });
	            this.loadLibs();
	        }
	    }, {
	        key: 'modalPageClick',
	        value: function modalPageClick(event) {
	            if (event === 'Ok') {
	                // надо найти активную строку

	                var boundField = this.props.boundToGrid ? this.props.boundToGrid : 'name',
	                    //grid filed name
	                boundToData = this.props.boundToData ? this.props.boundToData : false,
	                    //InputDefaultValue
	                boundFieldData = this.props.name; //inputName = fieldname

	                var activeRow = this.state.gridActiveRow,
	                    value = this.state.gridData[activeRow]['id'],
	                    fieldValue = this.state.gridData[activeRow][boundField];
	                // получить данные полей и установить состояние для виджета

	                // показать новое значение
	                this.setState({ value: value, fieldValue: fieldValue, show: false });

	                // вернуть значение наверх

	                if (this.props.onChange) {
	                    this.props.onChange(boundFieldData, value);

	                    // text value of input
	                    if (boundToData) {
	                        this.props.onChange(boundToData, fieldValue);
	                    }

	                    //если привязано другое поле
	                    if (this.props.collName) {
	                        this.props.onChange(this.props.collName, fieldValue);
	                    }
	                }
	            }
	        }
	    }, {
	        key: 'handleGridClick',
	        value: function handleGridClick(event, value, activeRow) {
	            this.setState({ gridActiveRow: activeRow });
	        }
	    }, {
	        key: 'loadLibs',
	        value: function loadLibs() {
	            var _this3 = this;

	            var postUrl = '/newApi/loadLibs';
	            var lib = this.props.libName;
	            var sqlWhere = '';
	            if (this.props.sqlFields.length && this.state.fieldValue) {
	                this.props.sqlFields.forEach(function (field) {
	                    var isOr = sqlWhere.length > 0 ? ' or ' : '';
	                    sqlWhere = sqlWhere.concat(' ' + isOr + ' encode(' + field + '::bytea, \'escape\') ilike \'%' + _this3.state.fieldValue.trim() + '%\'');
	                });
	                sqlWhere = 'where ' + sqlWhere;
	            }

	            var libParams = sqlWhere.length ? { sql: sqlWhere } : {};

	            fetchData.fetchDataPost(postUrl + '/' + lib, libParams).then(function (response) {
	                if (response && 'data' in response) {
	                    var gridData = response.data.result.result.data;
	                    _this3.setState({ gridData: gridData });
	                }
	            }).catch(function (error) {
	                console.error('loadLibs error', error);
	                rejected();
	            });
	        }
	    }]);

	    return SelectData;
	}(React.PureComponent);

	SelectData.propTypes = {
	    readOnly: PropTypes.bool,
	    disabled: PropTypes.bool,
	    collId: PropTypes.string,
	    title: PropTypes.string,
	    placeholder: PropTypes.string,
	    name: PropTypes.string.isRequired,
	    show: PropTypes.bool
	};

	SelectData.defaultProps = {
	    readOnly: false,
	    disabled: false,
	    btnDelete: false,
	    value: 0,
	    collId: 'id',
	    title: '',
	    show: false
	};

	module.exports = SelectData;

/***/ }),

/***/ 268:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _ = __webpack_require__(241);

	// осуществляет фильтрацию по значение и ищет во всех текстовых полях

	module.exports = function (data, filter) {
	    var result = data.filter(function (row) {

	        return !!_.find(row, function (value, key) {

	            if (typeof value === 'string' && value.includes(filter)) {
	                return true;
	            }
	        });
	    });
	    return result;
	};

/***/ }),

/***/ 269:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    wrapper: {
	        margin: '5px',
	        display: 'flex',
	        width: '95%'

	    },
	    input: {
	        width: '70%',
	        marginLeft: '5px',
	        borderRadius: '3px'

	    },
	    hide: {
	        display: 'none'
	    },
	    select: {
	        width: '60%',
	        marginLeft: '5px'
	    },
	    readOnly: {
	        backgroundColor: '#F3EFEF'
	    },
	    label: {
	        width: '30%',
	        margin: '5px'
	    },
	    button: {
	        width: '10%'
	    }

	};

/***/ }),

/***/ 270:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    docRow: {
	        display: 'flex',
	        flexDirection: 'row'
	        /*
	                border: '1px solid blue'
	        */
	    },
	    docColumn: {
	        display: 'flex',
	        flexDirection: 'column',
	        /*
	                border: '1px solid yellow',
	        */
	        width: '50%'
	    },
	    doc: {
	        display: 'flex',
	        flexDirection: 'column'
	        /*
	                border: '1px solid brown'
	        */
	    },

	    grid: {
	        mainTable: {
	            width: '100%'
	        },
	        headerTable: {
	            width: '100%'
	        },

	        gridContainer: {
	            width: '100%'
	        }

	    },

	    gridRow: {
	        /*
	                border: '1px solid black',
	        */
	        backgroundColor: 'white',
	        position: 'relative',
	        margin: '10% 30% 10% 30%',
	        width: 'auto',
	        opacity: '1',
	        top: '100px'
	    }

	};

/***/ }),

/***/ 271:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(6);
	var DocumentRegister = __webpack_require__(160);
	var styles = __webpack_require__(272);
	var DOC_TYPE_ID = 'VANEM';

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        return _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));
	    }

	    _createClass(Documents, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentRegister, { initData: this.props.initData,
	                userData: this.props.userData,
	                history: this.props.history ? this.props.history : null,
	                module: this.props.module,
	                ref: 'register',
	                docTypeId: DOC_TYPE_ID,
	                style: styles,
	                render: this.renderer });
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer() {
	            return React.createElement(
	                'div',
	                null,
	                'Vanemate register special render'
	            );
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 272:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    grid: {
	        mainTable: {
	            width: '100%'
	        },
	        headerTable: {
	            width: '100%'
	        },

	        gridContainer: {
	            width: '100%'
	        }

	    }
	};

/***/ })

});
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibGFwc2VkLmpzIiwic291cmNlcyI6WyJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvbGFwc2VkLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL21vZHVsZXMvbGFwc2VkLmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHMvZG9jdW1lbnQvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwcy9kb2N1bWVudC9sYXBzLnN0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHMvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwcy9sYXBzLXJlZ2lzdGVyLXN0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3ZhbmVtL2RvY3VtZW50L2luZGV4LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9jb21wb25lbnRzL3NlbGVjdC1kYXRhL3NlbGVjdC1kYXRhLmpzeCIsIndlYnBhY2s6Ly8vLi9saWJzL2dldERhdGFCeUZpbHRlci5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9jb21wb25lbnRzL3NlbGVjdC1kYXRhL3NlbGVjdC1kYXRhLXN0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3ZhbmVtL2RvY3VtZW50L3N0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3ZhbmVtL2luZGV4LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3ZhbmVtL3N0eWxlcy5qcyJdLCJzb3VyY2VzQ29udGVudCI6WyIndXNlIHN0cmljdCc7XG5cbnZhciBSZWFjdERPTSA9IHJlcXVpcmUoJ3JlYWN0LWRvbScpO1xuXG52YXIgX3JlcXVpcmUgPSByZXF1aXJlKCdyZWFjdC1yb3V0ZXItZG9tJyksXG4gICAgQnJvd3NlclJvdXRlciA9IF9yZXF1aXJlLkJyb3dzZXJSb3V0ZXI7XG5cbnZhciBEb2MgPSByZXF1aXJlKCcuLi9mcm9udGVuZC9tb2R1bGVzL2xhcHNlZC5qc3gnKTtcblxuaW5pdERhdGEgPSBKU09OLnBhcnNlKGluaXREYXRhKTtcbnVzZXJEYXRhID0gSlNPTi5wYXJzZSh1c2VyRGF0YSk7XG5cblJlYWN0RE9NLmh5ZHJhdGUoUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICBCcm93c2VyUm91dGVyLFxuICAgIG51bGwsXG4gICAgUmVhY3QuY3JlYXRlRWxlbWVudChEb2MsIHsgaW5pdERhdGE6IGluaXREYXRhLCB1c2VyRGF0YTogdXNlckRhdGEgfSlcbiksIGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCdkb2MnKSk7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9sYXBzZWQuanNcbi8vIG1vZHVsZSBpZCA9IDBcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG5cbnZhciBNZW51ID0gcmVxdWlyZSgnLi8uLi9jb21wb25lbnRzL21lbnUtdG9vbGJhci9tZW51LXRvb2xiYXIuanN4Jyk7XG5cbnZhciBEb2NzID0gcmVxdWlyZSgnLi8uLi9kb2NzL2Rvay9pbmRleC5qc3gnKTtcblxudmFyIExhcHNlRG9rdW1lbnQgPSByZXF1aXJlKCcuLy4uL2RvY3MvbGFwcy9kb2N1bWVudC9pbmRleC5qc3gnKTtcbnZhciBMYXN0ZVJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL2xhcHMvaW5kZXguanN4Jyk7XG5cbnZhciBWYW5lbURva3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL3ZhbmVtL2RvY3VtZW50L2luZGV4LmpzeCcpO1xudmFyIFZhbmVtYXRlUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3MvdmFuZW0vaW5kZXguanN4Jyk7XG5cbnZhciBBcnZlZGVSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9hcnYvaW5kZXguanN4Jyk7XG5cbnZhciBTbWtSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9zbWsvaW5kZXguanN4Jyk7XG5cbnZhciBTb3JkZXJpZGVSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9zb3JkZXIvaW5kZXguanN4Jyk7XG5cbnZhciBBc3V0dXNSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9hc3V0dXNlZC9pbmRleC5qc3gnKSxcbiAgICBBc3V0dXNEb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9hc3V0dXNlZC9kb2N1bWVudC9pbmRleC5qc3gnKTtcblxudmFyIF9yZXF1aXJlID0gcmVxdWlyZSgncmVhY3Qtcm91dGVyLWRvbScpLFxuICAgIFJvdXRlID0gX3JlcXVpcmUuUm91dGUsXG4gICAgd2l0aFJvdXRlciA9IF9yZXF1aXJlLndpdGhSb3V0ZXI7XG5cbnZhciBfcmVxdWlyZTIgPSByZXF1aXJlKCdyYWRpdW0nKSxcbiAgICBTdHlsZVJvb3QgPSBfcmVxdWlyZTIuU3R5bGVSb290O1xuXG52YXIgTU9EVUxFID0gJ0xhcHNlZCc7XG5cbnZhciBBcHAgPSBmdW5jdGlvbiAoX1JlYWN0JENvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhBcHAsIF9SZWFjdCRDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gQXBwKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBBcHApO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChBcHAuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihBcHApKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMucHJlcGFyZVBhcmFtc0ZvclRvb2xiYXIgPSBfdGhpcy5wcmVwYXJlUGFyYW1zRm9yVG9vbGJhci5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuc3RhdGUgPSB7XG4gICAgICAgICAgICB1c2VyRGF0YTogX3RoaXMucHJvcHMudXNlckRhdGFcbiAgICAgICAgfTtcbiAgICAgICAgX3RoaXMuY29tcG9uZXRzID0ge307XG4gICAgICAgIF90aGlzLnByZXBhcmVDb21wb25lbnRzKF90aGlzLmNvbXBvbmV0cyk7XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoQXBwLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgdmFyIF90aGlzMiA9IHRoaXM7XG5cbiAgICAgICAgICAgIHZhciBjb250ZXh0ID0ge307XG4gICAgICAgICAgICB2YXIgYnRuUGFyYW1zID0gdGhpcy5wcmVwYXJlUGFyYW1zRm9yVG9vbGJhcigpO1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICBTdHlsZVJvb3QsXG4gICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IHBhdGg6ICcvbGFwc2VkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChNZW51LCB7IHBhcmFtczogYnRuUGFyYW1zLCB1c2VyRGF0YTogX3RoaXMyLnN0YXRlLnVzZXJEYXRhLCBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZCcsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2NzLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksIHVzZXJEYXRhOiBfdGhpczIucHJvcHMudXNlckRhdGEsIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEsIG1vZHVsZTogTU9EVUxFIH0pO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL2RvY3MnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jcywgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LCB1c2VyRGF0YTogX3RoaXMyLnByb3BzLnVzZXJEYXRhLCBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLCBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9sYXBzJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KExhc3RlUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSwgdXNlckRhdGE6IF90aGlzMi5wcm9wcy51c2VyRGF0YSwgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSwgbW9kdWxlOiBNT0RVTEUgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvbGFwcy86ZG9jSWQnLCBjb21wb25lbnQ6IExhcHNlRG9rdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvdmFuZW0nLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVmFuZW1hdGVSZWdpc3RlciwgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LCB1c2VyRGF0YTogX3RoaXMyLnByb3BzLnVzZXJEYXRhLCBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLCBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC92YW5lbS86ZG9jSWQnLCBjb21wb25lbnQ6IFZhbmVtRG9rdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvYXJ2JyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KEFydmVkZVJlZ2lzdGVyLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksIHVzZXJEYXRhOiBfdGhpczIucHJvcHMudXNlckRhdGEsIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEsIG1vZHVsZTogTU9EVUxFIH0pO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3NtaycsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChTbWtSZWdpc3RlciwgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LCB1c2VyRGF0YTogX3RoaXMyLnByb3BzLnVzZXJEYXRhLCBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLCBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9zb3JkZXInLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU29yZGVyaWRlUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSwgdXNlckRhdGE6IF90aGlzMi5wcm9wcy51c2VyRGF0YSwgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSwgbW9kdWxlOiBNT0RVTEUgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvYXN1dHVzZWQvOmRvY0lkJywgY29tcG9uZW50OiBBc3V0dXNEb2N1bWVudCwgbW9kdWxlOiBNT0RVTEUgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvYXN1dHVzZWQnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQXN1dHVzUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSwgdXNlckRhdGE6IF90aGlzMi5wcm9wcy51c2VyRGF0YSwgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSwgbW9kdWxlOiBNT0RVTEUgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSlcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3ByZXBhcmVQYXJhbXNGb3JUb29sYmFyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHByZXBhcmVQYXJhbXNGb3JUb29sYmFyKCkge1xuICAgICAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgICAgICBidG5TdGFydDoge1xuICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBidG5Mb2dpbjoge1xuICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIGJ0bkFjY291bnQ6IHtcbiAgICAgICAgICAgICAgICAgICAgc2hvdzogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICB9O1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdwcmVwYXJlQ29tcG9uZW50cycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBwcmVwYXJlQ29tcG9uZW50cyhjb21wb25lbnRzKSB7XG4gICAgICAgICAgICByZXR1cm4gY29tcG9uZW50c1snTGFwc2VEb2N1bWVudCddID0gZnVuY3Rpb24gKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgdmFyIExhcHNlRG9jdW1lbnQgPSByZXF1aXJlKCcuLy4uL2RvY3MvbGFwcy9kb2N1bWVudC9pbmRleC5qc3gnKTtcbiAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChMYXBzZURvY3VtZW50LCBwcm9wcyk7XG4gICAgICAgICAgICB9O1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIEFwcDtcbn0oUmVhY3QuQ29tcG9uZW50KTtcblxubW9kdWxlLmV4cG9ydHMgPSBBcHA7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9tb2R1bGVzL2xhcHNlZC5qc3hcbi8vIG1vZHVsZSBpZCA9IDUxXG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcblxudmFyIERvY3VtZW50VGVtcGxhdGUgPSByZXF1aXJlKCcuLi8uLi9kb2N1bWVudFRlbXBsYXRlL2luZGV4LmpzeCcpLFxuICAgIElucHV0VGV4dCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtdGV4dC9pbnB1dC10ZXh0LmpzeCcpLFxuICAgIElucHV0TnVtYmVyID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC1udW1iZXIvaW5wdXQtbnVtYmVyLmpzeCcpLFxuICAgIFNlbGVjdCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvc2VsZWN0L3NlbGVjdC5qc3gnKSxcbiAgICBUZXh0QXJlYSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvdGV4dC1hcmVhL3RleHQtYXJlYS5qc3gnKSxcbiAgICBEYXRhR3JpZCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvZGF0YS1ncmlkL2RhdGEtZ3JpZC5qc3gnKSxcbiAgICByZWxhdGVkRG9jdW1lbnRzID0gcmVxdWlyZSgnLi4vLi4vLi4vbWl4aW4vcmVsYXRlZERvY3VtZW50cy5qc3gnKSxcbiAgICBNb2RhbFBhZ2UgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL21vZGFscGFnZS9tb2RhbFBhZ2UuanN4JyksXG4gICAgc3R5bGVzID0gcmVxdWlyZSgnLi9sYXBzLnN0eWxlcycpO1xuXG52YXIgTElCRE9LID0gJ0xBUFMnLFxuICAgIExJQlJBUklFUyA9IFsnYXN1dHVzZWQnXTtcblxudmFyIG5vdyA9IG5ldyBEYXRlKCk7XG5cbnZhciBMYXBzID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKExhcHMsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIExhcHMocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIExhcHMpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChMYXBzLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoTGFwcykpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIGxvYWRlZERhdGE6IGZhbHNlLFxuICAgICAgICAgICAgZG9jSWQ6IHByb3BzLmRvY0lkID8gcHJvcHMuZG9jSWQgOiBOdW1iZXIocHJvcHMubWF0Y2gucGFyYW1zLmRvY0lkKVxuICAgICAgICB9O1xuXG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmhhbmRsZVBhZ2VDbGljayA9IF90aGlzLmhhbmRsZVBhZ2VDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlVGVlbnVzdGVHcmlkQnRuQ2xpY2sgPSBfdGhpcy5oYW5kbGVUZWVudXN0ZUdyaWRCdG5DbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlVmFuZW1hZEdyaWRCdG5DbGljayA9IF90aGlzLmhhbmRsZVZhbmVtYWRHcmlkQnRuQ2xpY2suYmluZChfdGhpcyk7XG5cbiAgICAgICAgX3RoaXMucGFnZXMgPSBbeyBwYWdlTmFtZTogJ0xhcHNlIGthYXJ0JywgZG9jVHlwZUlkOiAnTEFQUycgfSwgeyBwYWdlTmFtZTogJ0FydmVkJywgaGFuZGxlUGFnZUNsaWNrOiBfdGhpcy5oYW5kbGVQYWdlQ2xpY2ssIGRvY1R5cGVJZDogJ0FSVicgfSwgeyBwYWdlTmFtZTogJ01ha3Nla29yYWxkdXNlZCcsIGhhbmRsZVBhZ2VDbGljazogX3RoaXMuaGFuZGxlUGFnZUNsaWNrLCBkb2NUeXBlSWQ6ICdTTUsnIH0sIHsgcGFnZU5hbWU6ICdLYXNzYW9yZGVyaWQnLCBoYW5kbGVQYWdlQ2xpY2s6IF90aGlzLmhhbmRsZVBhZ2VDbGljaywgZG9jVHlwZUlkOiAnU09SREVSJyB9XTtcbiAgICAgICAgX3RoaXMucmVxdWlyZWRGaWVsZHMgPSBbe1xuICAgICAgICAgICAgbmFtZTogJ2lzaWt1a29vZCcsXG4gICAgICAgICAgICB0eXBlOiAnQydcbiAgICAgICAgfSwgeyBuYW1lOiAnbmltaScsIHR5cGU6ICdDJyB9XTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhMYXBzLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgdmFyIGluaXREYXRhID0gdGhpcy5wcm9wcy5pbml0RGF0YSA/IHRoaXMucHJvcHMuaW5pdERhdGEgOiB7fTtcblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRUZW1wbGF0ZSwgeyBkb2NJZDogdGhpcy5zdGF0ZS5kb2NJZCxcbiAgICAgICAgICAgICAgICByZWY6ICdkb2N1bWVudCcsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiAnTEFQUycsXG4gICAgICAgICAgICAgICAgcmVxdWlyZWRGaWVsZHM6IHRoaXMucmVxdWlyZWRGaWVsZHMsXG4gICAgICAgICAgICAgICAgdXNlckRhdGE6IHRoaXMucHJvcHMudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgaW5pdERhdGE6IGluaXREYXRhLFxuICAgICAgICAgICAgICAgIGxpYnM6IExJQlJBUklFUyxcbiAgICAgICAgICAgICAgICBwYWdlczogdGhpcy5wYWdlcyxcbiAgICAgICAgICAgICAgICByZW5kZXJlcjogdGhpcy5yZW5kZXJlcixcbiAgICAgICAgICAgICAgICBjcmVhdGVHcmlkUm93OiB0aGlzLmNyZWF0ZUdyaWRSb3csXG4gICAgICAgICAgICAgICAgZ3JpZFZhbGlkYXRvcjogdGhpcy5ncmlkVmFsaWRhdGVGaWVsZHMsXG4gICAgICAgICAgICAgICAgZm9jdXNFbGVtZW50OiAnaW5wdXQtaXNpa3Vrb29kJ1xuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKtCS0LXRgNC90LXRgiDQutCw0YHRgtC+0LzQvdGL0LUg0LrQvtC80L/QvtC90LXQvdGC0Ysg0LTQvtC60YPQvNC10L3RgtCwXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcmVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcmVyKHNlbGYpIHtcbiAgICAgICAgICAgIHZhciBicG0gPSBzZWxmLmRvY0RhdGEgJiYgc2VsZi5kb2NEYXRhLmJwbSA/IHNlbGYuZG9jRGF0YS5icG0gOiBbXSxcbiAgICAgICAgICAgICAgICBpc0VkaXRNb2RlID0gc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgZ3JpZFZhbmVtYWREYXRhID0gc2VsZi5kb2NEYXRhLnZhbmVtYWQsXG4gICAgICAgICAgICAgICAgZ3JpZFZhbmVtYWRDb2x1bW5zID0gc2VsZi5kb2NEYXRhLmdyaWRDb25maWcsXG4gICAgICAgICAgICAgICAgZ3JpZFRlZW51c3RlRGF0YSA9IHNlbGYuZG9jRGF0YS50ZWVudXNlZCxcbiAgICAgICAgICAgICAgICBncmlkVGVlbnVzdGVDb2x1bW5zID0gc2VsZi5kb2NEYXRhLmdyaWRUZWVudXN0ZUNvbmZpZztcblxuICAgICAgICAgICAgLy8g0YTQvtGA0LzQuNGA0YPQtdC8INC30LDQstC40YHQuNC80L7RgdGC0LhcbiAgICAgICAgICAgIGlmIChzZWxmLmRvY0RhdGEucmVsYXRpb25zKSB7XG4gICAgICAgICAgICAgICAgcmVsYXRlZERvY3VtZW50cyhzZWxmKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgdmFyIGRvYyA9IHRoaXMucmVmc1snZG9jdW1lbnQnXTtcbiAgICAgICAgICAgIHZhciBsaWJzID0gZG9jID8gZG9jLmxpYnMgOiB7fTtcblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvYyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyByZWY6ICdpbnB1dC1pc2lrdWtvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aXRsZTogJ0lzaWt1a29vZDonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnaXNpa3Vrb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5pc2lrdWtvb2QgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdOaW1pOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICduaW1pJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5uaW1pIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1uaW1pJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ1ZpaXRlbnVtYmVyOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICd2aWl0ZW51bWJlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEudmlpdGVudW1iZXIgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXZpaXRlbnVtYmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHJlZjogJ2lucHV0LWphYWsnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aXRsZTogJ0pcXHhFNFxceEU0azonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnamFhaycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuamFhayB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6IHRydWVcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFRleHRBcmVhLCB7IHRpdGxlOiAnTVxceEU0cmt1c2VkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5tdXVkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdsYWJlbCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyByZWY6ICdsYWJlbCcgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnVmFuZW1hZCdcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEYXRhR3JpZCwgeyBzb3VyY2U6ICd2YW5lbWFkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBncmlkRGF0YTogZ3JpZFZhbmVtYWREYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGdyaWRDb2x1bW5zOiBncmlkVmFuZW1hZENvbHVtbnMsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc2hvd1Rvb2xCYXI6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogdGhpcy5oYW5kbGVWYW5lbWFkR3JpZEJ0bkNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLmdyaWQuaGVhZGVyVGFibGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndmFuZW1hZC1kYXRhLWdyaWQnIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2xhYmVsJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ2xhYmVsJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdUZWVudXNlZCdcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEYXRhR3JpZCwgeyBzb3VyY2U6ICd0ZWVudXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZERhdGE6IGdyaWRUZWVudXN0ZURhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZENvbHVtbnM6IGdyaWRUZWVudXN0ZUNvbHVtbnMsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc2hvd1Rvb2xCYXI6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogdGhpcy5oYW5kbGVUZWVudXN0ZUdyaWRCdG5DbGljayxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGU6IHN0eWxlcy5ncmlkLmhlYWRlclRhYmxlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3RlZW51c3RlLWRhdGEtZ3JpZCcgfSlcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVBhZ2VDbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVQYWdlQ2xpY2socGFnZURvY1R5cGVJZCkge1xuICAgICAgICAgICAgLy8gICAgICAgIGRvY3VtZW50LmxvY2F0aW9uLmhyZWYgPSBgL2xhcHNlZC8ke3BhZ2VEb2NUeXBlSWR9L2A7Ly9AdG9kbyDQntCx0L3QvtCy0LjRgtGMXG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC8nICsgcGFnZURvY1R5cGVJZCk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVRlZW51c3RlR3JpZEJ0bkNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZVRlZW51c3RlR3JpZEJ0bkNsaWNrKGJ0bk5hbWUpIHtcbiAgICAgICAgICAgIGNvbnNvbGUubG9nKCd0ZWVudXN0ZSBoYW5kbGVHcmlkQnRuQ2xpY2snLCBidG5OYW1lKTtcbiAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKCcvbGFwc2VkL3RlZW51c2VkLycgKyBpZCk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVZhbmVtYWRHcmlkQnRuQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaGFuZGxlVmFuZW1hZEdyaWRCdG5DbGljayhidG5OYW1lKSB7XG4gICAgICAgICAgICBjb25zb2xlLmxvZygndmFuZW1hZCBoYW5kbGVHcmlkQnRuQ2xpY2snLCBidG5OYW1lKTtcbiAgICAgICAgICAgIHZhciBpZCA9IDA7XG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC92YW5lbWFkLycgKyBpZCk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gTGFwcztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbkxhcHMucHJvcFR5cGVzID0ge1xuICAgIGRvY0lkOiBQcm9wVHlwZXMubnVtYmVyLFxuICAgIGluaXREYXRhOiBQcm9wVHlwZXMub2JqZWN0LFxuICAgIHVzZXJEYXRhOiBQcm9wVHlwZXMub2JqZWN0XG59O1xuXG5MYXBzLmRlZmF1bHRQcm9wcyA9IHtcbiAgICBwYXJhbXM6IHsgZG9jSWQ6IDAgfSxcbiAgICBpbml0RGF0YToge30sXG4gICAgdXNlckRhdGE6IHt9XG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IExhcHM7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHMvZG9jdW1lbnQvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyMzlcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBkb2NSb3c6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAncm93J1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsdWUnXHJcbiAgICAgICAgKi9cbiAgICB9LFxuICAgIGRvY0NvbHVtbjoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nLFxuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIHllbGxvdycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgd2lkdGg6ICc1MCUnXG4gICAgfSxcbiAgICBkb2M6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJ1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJyb3duJ1xyXG4gICAgICAgICovXG4gICAgfSxcblxuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9LFxuXG4gICAgZ3JpZFJvdzoge1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsYWNrJyxcclxuICAgICAgICAqL1xuICAgICAgICBiYWNrZ3JvdW5kQ29sb3I6ICd3aGl0ZScsXG4gICAgICAgIHBvc2l0aW9uOiAncmVsYXRpdmUnLFxuICAgICAgICBtYXJnaW46ICcxMCUgMzAlIDEwJSAzMCUnLFxuICAgICAgICB3aWR0aDogJ2F1dG8nLFxuICAgICAgICBvcGFjaXR5OiAnMScsXG4gICAgICAgIHRvcDogJzEwMHB4J1xuICAgIH1cblxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvbGFwcy9kb2N1bWVudC9sYXBzLnN0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjYzXG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIERvY3VtZW50UmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3VtZW50cy9kb2N1bWVudHMuanN4Jyk7XG52YXIgc3R5bGVzID0gcmVxdWlyZSgnLi9sYXBzLXJlZ2lzdGVyLXN0eWxlcycpO1xudmFyIERPQ19UWVBFX0lEID0gJ0xBUFMnO1xuXG4vKipcclxuICog0JrQu9Cw0YHRgSDRgNC10LDQu9C40LfRg9C10YIg0LTQvtC60YPQvNC10L3RgiDRgdC/0YDQsNCy0L7Rh9C90LjQutCwINC/0YDQuNC30L3QsNC60L7Qsi5cclxuICovXG5cbnZhciBEb2N1bWVudHMgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoRG9jdW1lbnRzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBEb2N1bWVudHMocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIERvY3VtZW50cyk7XG5cbiAgICAgICAgcmV0dXJuIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChEb2N1bWVudHMuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihEb2N1bWVudHMpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKERvY3VtZW50cywgW3tcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50UmVnaXN0ZXIsIHsgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgdXNlckRhdGE6IHRoaXMucHJvcHMudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICBtb2R1bGU6IHRoaXMucHJvcHMubW9kdWxlLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6IERPQ19UWVBFX0lELFxuICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMsXG4gICAgICAgICAgICAgICAgcmVuZGVyOiB0aGlzLnJlbmRlcmVyIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgJ0xhc3RlIHJlZ2lzdGVyIHNwZWNpYWwgcmVuZGVyJ1xuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBEb2N1bWVudHM7XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5tb2R1bGUuZXhwb3J0cyA9IERvY3VtZW50cztcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvbGFwcy9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDI2NFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9XG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzL2xhcHMtcmVnaXN0ZXItc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyNjVcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBQcm9wVHlwZXMgPSByZXF1aXJlKCdwcm9wLXR5cGVzJyk7XG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xuXG52YXIgRG9jdW1lbnRUZW1wbGF0ZSA9IHJlcXVpcmUoJy4uLy4uL2RvY3VtZW50VGVtcGxhdGUvaW5kZXguanN4JyksXG4gICAgSW5wdXRUZXh0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC10ZXh0L2lucHV0LXRleHQuanN4JyksXG4gICAgU2VsZWN0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3Qvc2VsZWN0LmpzeCcpLFxuICAgIEJ1dHRvbkVkaXQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2J1dHRvbi1yZWdpc3Rlci9idXR0b24tcmVnaXN0ZXItZWRpdC9idXR0b24tcmVnaXN0ZXItZWRpdC5qc3gnKSxcbiAgICBTZWxlY3REYXRhID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3QtZGF0YS9zZWxlY3QtZGF0YS5qc3gnKSxcbiAgICBUZXh0QXJlYSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvdGV4dC1hcmVhL3RleHQtYXJlYS5qc3gnKSxcbiAgICBEYXRhR3JpZCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvZGF0YS1ncmlkL2RhdGEtZ3JpZC5qc3gnKSxcbiAgICBNb2RhbFBhZ2UgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL21vZGFscGFnZS9tb2RhbFBhZ2UuanN4JyksXG4gICAgc3R5bGVzID0gcmVxdWlyZSgnLi9zdHlsZXMnKTtcblxudmFyIExJQkRPSyA9ICdWQU5FTScsXG4gICAgTElCUkFSSUVTID0gW107XG5cbnZhciBub3cgPSBuZXcgRGF0ZSgpO1xuXG52YXIgVmFuZW0gPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoVmFuZW0sIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIFZhbmVtKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBWYW5lbSk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKFZhbmVtLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoVmFuZW0pKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMuc3RhdGUgPSB7XG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZClcbiAgICAgICAgfTtcblxuICAgICAgICBfdGhpcy5yZW5kZXJlciA9IF90aGlzLnJlbmRlcmVyLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5oYW5kbGVQYWdlQ2xpY2sgPSBfdGhpcy5oYW5kbGVQYWdlQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmhhbmRsZUxhc3RlR3JpZEJ0bkNsaWNrID0gX3RoaXMuaGFuZGxlTGFzdGVHcmlkQnRuQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmJ0bkVkaXRBc3V0dXNDbGljayA9IF90aGlzLmJ0bkVkaXRBc3V0dXNDbGljay5iaW5kKF90aGlzKTtcblxuICAgICAgICBfdGhpcy5wYWdlcyA9IFt7IHBhZ2VOYW1lOiAnVmFuZW0ga2FhcnQnLCBkb2NUeXBlSWQ6ICdWQU5FTScgfSwgeyBwYWdlTmFtZTogJ0FydmVkJywgaGFuZGxlUGFnZUNsaWNrOiBfdGhpcy5oYW5kbGVQYWdlQ2xpY2ssIGRvY1R5cGVJZDogJ0FSVicgfSwgeyBwYWdlTmFtZTogJ01ha3Nla29yYWxkdXNlZCcsIGhhbmRsZVBhZ2VDbGljazogX3RoaXMuaGFuZGxlUGFnZUNsaWNrLCBkb2NUeXBlSWQ6ICdTTUsnIH0sIHsgcGFnZU5hbWU6ICdLYXNzYW9yZGVyaWQnLCBoYW5kbGVQYWdlQ2xpY2s6IF90aGlzLmhhbmRsZVBhZ2VDbGljaywgZG9jVHlwZUlkOiAnU09SREVSJyB9XTtcbiAgICAgICAgX3RoaXMucmVxdWlyZWRGaWVsZHMgPSBbe1xuICAgICAgICAgICAgbmFtZTogJ2FzdXR1c2lkJyxcbiAgICAgICAgICAgIHR5cGU6ICdJJ1xuICAgICAgICB9LCB7IG5hbWU6ICdwYXJlbnRpZCcsIHR5cGU6ICdJJyB9XTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhWYW5lbSwgW3tcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHZhciBpbml0RGF0YSA9IHRoaXMucHJvcHMuaW5pdERhdGEgPyB0aGlzLnByb3BzLmluaXREYXRhIDoge307XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50VGVtcGxhdGUsIHsgZG9jSWQ6IHRoaXMuc3RhdGUuZG9jSWQsXG4gICAgICAgICAgICAgICAgcmVmOiAnZG9jdW1lbnQnLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ1ZBTkVNJyxcbiAgICAgICAgICAgICAgICByZXF1aXJlZEZpZWxkczogdGhpcy5yZXF1aXJlZEZpZWxkcyxcbiAgICAgICAgICAgICAgICB1c2VyRGF0YTogdGhpcy5wcm9wcy51c2VyRGF0YSxcbiAgICAgICAgICAgICAgICBpbml0RGF0YTogaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgbGliczogTElCUkFSSUVTLFxuICAgICAgICAgICAgICAgIHBhZ2VzOiB0aGlzLnBhZ2VzLFxuICAgICAgICAgICAgICAgIHJlbmRlcmVyOiB0aGlzLnJlbmRlcmVyLFxuICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogdGhpcy5oYW5kbGVMYXN0ZUdyaWRCdG5DbGljayxcbiAgICAgICAgICAgICAgICBmb2N1c0VsZW1lbnQ6ICdpbnB1dC1pc2lrdWtvb2QnXG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAq0JLQtdGA0L3QtdGCINC60LDRgdGC0L7QvNC90YvQtSDQutC+0LzQv9C+0L3QtdC90YLRiyDQtNC+0LrRg9C80LXQvdGC0LBcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgdmFyIGlzRWRpdE1vZGUgPSBzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICBncmlkTGFzdGVEYXRhID0gc2VsZi5kb2NEYXRhLmxhcHNlZCxcbiAgICAgICAgICAgICAgICBncmlkTGFzdGVDb2x1bW5zID0gc2VsZi5kb2NEYXRhLmdyaWRDb25maWc7XG5cbiAgICAgICAgICAgIC8vINGE0L7RgNC80LjRgNGD0LXQvCDQt9Cw0LLQuNGB0LjQvNC+0YHRgtC4XG4gICAgICAgICAgICBpZiAoc2VsZi5kb2NEYXRhLnJlbGF0aW9ucykge1xuICAgICAgICAgICAgICAgIHJlbGF0ZWREb2N1bWVudHMoc2VsZik7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHZhciBhc3V0dXNHcmlkID0gW3sgaWQ6IFwiaWRcIiwgbmFtZTogXCJpZFwiLCB3aWR0aDogXCI1MHB4XCIsIHNob3c6IGZhbHNlIH0sIHsgaWQ6IFwicmVna29vZFwiLCBuYW1lOiBcIklzaWt1a29vZFwiLCB3aWR0aDogXCIxMDBweFwiIH0sIHsgaWQ6IFwibmltZXR1c1wiLCBuYW1lOiBcIk5pbWlcIiwgd2lkdGg6IFwiMTAwcHhcIiB9XTtcblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvYyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdERhdGEsIHsgdGl0bGU6ICdWYW5lbTonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2FzdXR1c2lkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYk5hbWU6ICdhc3V0dXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzcWxGaWVsZHM6IFsnbmltZXR1cycsICdyZWdrb29kJ10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBbXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbmZpZzogYXN1dHVzR3JpZCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuYXN1dHVzaWQgfHwgMCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlZmF1bHRWYWx1ZTogc2VsZi5kb2NEYXRhLnZhbmVtX25pbWksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBib3VuZFRvR3JpZDogJ25pbWV0dXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYm91bmRUb0RhdGE6ICd2YW5lbV9uaW1pJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3NlbGVjdC1hc3V0dXNpZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBidG5EZWxldGU6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQnV0dG9uRWRpdCwge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnYnRuRWRpdCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrOiB0aGlzLmJ0bkVkaXRBc3V0dXNDbGljayxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNob3c6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ1N1Z3VsdXM6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3N1aHR1bWluZScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuc3VodHVtaW5lIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1zdWh0dW1pbmUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnQXJ2ZWxkdXM6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2FydmVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogW3sgbmFtZTogJ0phaCcgfSwgeyBuYW1lOiAnRWknIH1dLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFydmVkIHx8ICdFaScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGxJZDogJ25hbWUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHNlbGYuZG9jRGF0YS5hcnZlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LWFydmVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYnRuRGVsZXRlOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFRleHRBcmVhLCB7IHRpdGxlOiAnTVxceEU0cmt1c2VkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5tdXVkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdsYWJlbCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyByZWY6ICdsYWJlbCcgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnTGFwc2VkJ1xuICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KERhdGFHcmlkLCB7IHNvdXJjZTogJ2xhcHNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZERhdGE6IGdyaWRMYXN0ZURhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZENvbHVtbnM6IGdyaWRMYXN0ZUNvbHVtbnMsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc2hvd1Rvb2xCYXI6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogc2VsZi5oYW5kbGVHcmlkQnRuQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMuZ3JpZC5oZWFkZXJUYWJsZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdsYXNwc2VkLWRhdGEtZ3JpZCcgfSlcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVBhZ2VDbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVQYWdlQ2xpY2socGFnZURvY1R5cGVJZCkge1xuICAgICAgICAgICAgLy8gICAgICAgIGRvY3VtZW50LmxvY2F0aW9uLmhyZWYgPSBgL2xhcHNlZC8ke3BhZ2VEb2NUeXBlSWR9L2A7Ly9AdG9kbyDQntCx0L3QvtCy0LjRgtGMXG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC8nICsgcGFnZURvY1R5cGVJZCk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZUxhc3RlR3JpZEJ0bkNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZUxhc3RlR3JpZEJ0bkNsaWNrKGJ0bk5hbWUsIGlkKSB7XG5cbiAgICAgICAgICAgIHN3aXRjaCAoYnRuTmFtZSkge1xuICAgICAgICAgICAgICAgIGNhc2UgXCJlZGl0XCI6XG4gICAgICAgICAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKCcvbGFwc2VkL2xhcHMvJyArIGlkKTtcblxuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICBjYXNlIFwiYWRkXCI6XG4gICAgICAgICAgICAgICAgICAgIGNvbnNvbGUubG9nKCdidG5BZGQgY2xpY2tlZCcpO1xuICAgICAgICAgICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC9sYXBzLzAnKTtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgY2FzZSBcImRlbGV0ZVwiOlxuICAgICAgICAgICAgICAgICAgICBjb25zb2xlLmxvZygnYnRuRGVsZXRlIGNsaWNrZWQnKTtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgZGVmYXVsdDpcbiAgICAgICAgICAgICAgICAgICAgY29uc29sZS5sb2coJ1ZpZ2FuZSBjbGljaycpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgLy8g0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0LrQu9C40YHQutCwINC90LAg0LrQvdC+0L/QutC1INGA0LXQtNCw0LrRgtC40YDQvtCy0LDQvdC40Y8g0LrQvtC90YLRgC3QsNCz0LXQvdGC0LBcblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnYnRuRWRpdEFzdXR1c0NsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGJ0bkVkaXRBc3V0dXNDbGljaygpIHtcbiAgICAgICAgICAgIHZhciBkb2NBc3V0dXNJZCA9IHRoaXMucmVmc1snZG9jdW1lbnQnXS5kb2NEYXRhLmFzdXR1c2lkO1xuXG4gICAgICAgICAgICAvLyDQvtGB0YPRidC10YHRgtCy0LjRgiDQv9C10YDQtdGF0L7QtCDQvdCwINC60LDRgNGC0L7Rh9C60YMg0LrQvtC90YLRgC3QsNCz0LXQvdGC0LBcbiAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKCcvbGFwc2VkL2FzdXR1c2VkLycgKyBkb2NBc3V0dXNJZCk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gVmFuZW07XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5WYW5lbS5wcm9wVHlwZXMgPSB7XG4gICAgZG9jSWQ6IFByb3BUeXBlcy5udW1iZXIsXG4gICAgaW5pdERhdGE6IFByb3BUeXBlcy5vYmplY3QsXG4gICAgdXNlckRhdGE6IFByb3BUeXBlcy5vYmplY3Rcbn07XG5cblZhbmVtLmRlZmF1bHRQcm9wcyA9IHtcbiAgICBwYXJhbXM6IHsgZG9jSWQ6IDAgfSxcbiAgICBpbml0RGF0YToge30sXG4gICAgdXNlckRhdGE6IHt9XG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IFZhbmVtO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy92YW5lbS9kb2N1bWVudC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDI2NlxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFByb3BUeXBlcyA9IHJlcXVpcmUoJ3Byb3AtdHlwZXMnKTtcbnZhciBnZXREYXRhQnlGaWx0ZXIgPSByZXF1aXJlKCcuLi8uLi8uLi9saWJzL2dldERhdGFCeUZpbHRlcicpO1xudmFyIGZldGNoRGF0YSA9IHJlcXVpcmUoJy4vLi4vLi4vLi4vbGlicy9mZXRjaERhdGEnKTtcblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKSxcbiAgICBzdHlsZXMgPSByZXF1aXJlKCcuL3NlbGVjdC1kYXRhLXN0eWxlcycpLFxuICAgIERhdGFHcmlkID0gcmVxdWlyZSgnLi4vLi4vY29tcG9uZW50cy9kYXRhLWdyaWQvZGF0YS1ncmlkLmpzeCcpLFxuICAgIEJ1dHRvbiA9IHJlcXVpcmUoJy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi1yZWdpc3Rlci5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBNb2RhbFBhZ2UgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvbW9kYWxwYWdlL21vZGFsUGFnZS5qc3gnKTtcblxudmFyIFNlbGVjdERhdGEgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoU2VsZWN0RGF0YSwgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gU2VsZWN0RGF0YShwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgU2VsZWN0RGF0YSk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKFNlbGVjdERhdGEuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihTZWxlY3REYXRhKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgdmFsdWU6IHByb3BzLnZhbHVlLCAvKiDQstC+0LfQstGA0LDRidCw0LXQvNC+0LUg0LfQvdCw0YfQtdC90LjQtSwg0L3QsNC/0YDQuNC80LXRgCBpZCovXG4gICAgICAgICAgICBmaWVsZFZhbHVlOiBwcm9wcy5kZWZhdWx0VmFsdWUsIC8q0LLQuNC00LjQvNC+0LUg0LfQvdCw0YfQtdC90LjQtSwg0L3QsNC/0YDQuNC80LXRgCBrb29kINC40LvQuCBuYW1lINC/0L4g0YPQutCw0LfQsNC90L3QvtC80YMg0LIgY29sbElkICovXG4gICAgICAgICAgICByZWFkT25seTogcHJvcHMucmVhZE9ubHksXG4gICAgICAgICAgICBkaXNhYmxlZDogcHJvcHMuZGlzYWJsZWQsXG4gICAgICAgICAgICBlZGl0ZWQ6IHByb3BzLmVkaXRlZCxcbiAgICAgICAgICAgIGdyaWREYXRhOiBbXSxcbiAgICAgICAgICAgIGdyaWRDb25maWc6IHByb3BzLmNvbmZpZyxcbiAgICAgICAgICAgIGdyaWRBY3RpdmVSb3c6IDAsXG4gICAgICAgICAgICBzaG93OiBfdGhpcy5wcm9wcy5zaG93XG4gICAgICAgIH07XG4gICAgICAgIC8vICAgICAgICB0aGlzLm9uQ2hhbmdlID0gdGhpcy5vbkNoYW5nZS5iaW5kKHRoaXMpO1xuICAgICAgICBfdGhpcy5oYW5kbGVJbnB1dENoYW5nZSA9IF90aGlzLmhhbmRsZUlucHV0Q2hhbmdlLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5oYW5kbGVHcmlkQ2xpY2sgPSBfdGhpcy5oYW5kbGVHcmlkQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLm1vZGFsUGFnZUNsaWNrID0gX3RoaXMubW9kYWxQYWdlQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmxvYWRMaWJzID0gX3RoaXMubG9hZExpYnMuYmluZChfdGhpcyk7XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoU2VsZWN0RGF0YSwgW3tcbiAgICAgICAga2V5OiAnY29tcG9uZW50V2lsbFJlY2VpdmVQcm9wcycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBjb21wb25lbnRXaWxsUmVjZWl2ZVByb3BzKG5leHRQcm9wcykge1xuXG4gICAgICAgICAgICB0aGlzLnNldFN0YXRlKHtcbiAgICAgICAgICAgICAgICB2YWx1ZTogbmV4dFByb3BzLnZhbHVlLFxuICAgICAgICAgICAgICAgIGZpZWxkVmFsdWU6IG5leHRQcm9wcy5kZWZhdWx0VmFsdWUsXG4gICAgICAgICAgICAgICAgcmVhZE9ubHk6IG5leHRQcm9wcy5yZWFkT25seSxcbiAgICAgICAgICAgICAgICBzaG93OiBuZXh0UHJvcHMuc2hvd1xuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICB2YXIgX3RoaXMyID0gdGhpcztcblxuICAgICAgICAgICAgdmFyIGlzRWRpdGVNb2RlID0gIXRoaXMuc3RhdGUucmVhZE9ubHksXG4gICAgICAgICAgICAgICAgYnRuU3R5bGUgPSBPYmplY3QuYXNzaWduKHt9LCBzdHlsZXMuYnV0dG9uLCB7IGRpc3BsYXk6IGlzRWRpdGVNb2RlID8gJ2lubGluZScgOiAnbm9uZScgfSk7XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy53cmFwcGVyIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgcmVmOiAnaW5wdXQnLFxuICAgICAgICAgICAgICAgICAgICB0aXRsZTogdGhpcy5wcm9wcy50aXRsZSxcbiAgICAgICAgICAgICAgICAgICAgbmFtZTogdGhpcy5wcm9wcy5uYW1lLFxuICAgICAgICAgICAgICAgICAgICB2YWx1ZTogdGhpcy5zdGF0ZS5maWVsZFZhbHVlLFxuICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdGVNb2RlLFxuICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEJ1dHRvbiwgeyB2YWx1ZTogJ3YnLFxuICAgICAgICAgICAgICAgICAgICByZWY6ICdidG5TaG93JyxcbiAgICAgICAgICAgICAgICAgICAgc3R5bGU6IGJ0blN0eWxlLFxuICAgICAgICAgICAgICAgICAgICBvbkNsaWNrOiBmdW5jdGlvbiBvbkNsaWNrKGUpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBfdGhpczIuaGFuZGxlQ2xpY2soZSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgdGhpcy5zdGF0ZS5zaG93ID8gdGhpcy5tb2RhbFBhZ2UoKSA6IG51bGxcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZUNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZUNsaWNrKGUpIHtcbiAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoe1xuICAgICAgICAgICAgICAgIHNob3c6IHRydWVcbiAgICAgICAgICAgIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdtb2RhbFBhZ2UnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gbW9kYWxQYWdlKCkge1xuICAgICAgICAgICAgdmFyIG1vZGFsT2JqZWN0cyA9IFsnYnRuT2snLCAnYnRuQ2FuY2VsJ107XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgTW9kYWxQYWdlLFxuICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICBtb2RhbE9iamVjdHM6IG1vZGFsT2JqZWN0cyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ21vZGFscGFnZS1ncmlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICBtb2RhbFBhZ2VCdG5DbGljazogdGhpcy5tb2RhbFBhZ2VDbGljayxcbiAgICAgICAgICAgICAgICAgICAgICAgIG1vZGFsUGFnZU5hbWU6ICdWYWxpIHJlYScgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWY6ICdncmlkLXJvdy1jb250YWluZXInIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyByZWY6ICdpbnB1dC1maWx0ZXInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpdGxlOiAnT3RzaW5ndSBwYXJhbWV0cmlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnZ3JpZEZpbHRlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHRoaXMuc3RhdGUuZmllbGRWYWx1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHRoaXMuaGFuZGxlSW5wdXRDaGFuZ2UgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KERhdGFHcmlkLCB7IGdyaWREYXRhOiB0aGlzLnN0YXRlLmdyaWREYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGdyaWRDb2x1bW5zOiB0aGlzLnN0YXRlLmdyaWRDb25maWcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DbGljazogdGhpcy5oYW5kbGVHcmlkQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnZGF0YS1ncmlkJyB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8vINC+0LHRgNCw0LHQvtGC0YfQuNC6INGB0L7QsdGL0YLQuNGPINC40LfQvNC10L3QuNGPINC30L3QsNGH0LXQvdC40Y8g0LIg0YLQtdC60YHRgtC+0LLQvtC8ICjQv9C+0LjRgdC60L7QstC+0LwpINC/0L7Qu9C1XG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZUlucHV0Q2hhbmdlJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZUlucHV0Q2hhbmdlKG5hbWUsIHZhbHVlKSB7XG4gICAgICAgICAgICB0aGlzLnNldFN0YXRlKHsgZmllbGRWYWx1ZTogdmFsdWUsIHNob3c6IHRydWUgfSk7XG4gICAgICAgICAgICB0aGlzLmxvYWRMaWJzKCk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ21vZGFsUGFnZUNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIG1vZGFsUGFnZUNsaWNrKGV2ZW50KSB7XG4gICAgICAgICAgICBpZiAoZXZlbnQgPT09ICdPaycpIHtcbiAgICAgICAgICAgICAgICAvLyDQvdCw0LTQviDQvdCw0LnRgtC4INCw0LrRgtC40LLQvdGD0Y4g0YHRgtGA0L7QutGDXG5cbiAgICAgICAgICAgICAgICB2YXIgYm91bmRGaWVsZCA9IHRoaXMucHJvcHMuYm91bmRUb0dyaWQgPyB0aGlzLnByb3BzLmJvdW5kVG9HcmlkIDogJ25hbWUnLFxuICAgICAgICAgICAgICAgICAgICAvL2dyaWQgZmlsZWQgbmFtZVxuICAgICAgICAgICAgICAgIGJvdW5kVG9EYXRhID0gdGhpcy5wcm9wcy5ib3VuZFRvRGF0YSA/IHRoaXMucHJvcHMuYm91bmRUb0RhdGEgOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgLy9JbnB1dERlZmF1bHRWYWx1ZVxuICAgICAgICAgICAgICAgIGJvdW5kRmllbGREYXRhID0gdGhpcy5wcm9wcy5uYW1lOyAvL2lucHV0TmFtZSA9IGZpZWxkbmFtZVxuXG4gICAgICAgICAgICAgICAgdmFyIGFjdGl2ZVJvdyA9IHRoaXMuc3RhdGUuZ3JpZEFjdGl2ZVJvdyxcbiAgICAgICAgICAgICAgICAgICAgdmFsdWUgPSB0aGlzLnN0YXRlLmdyaWREYXRhW2FjdGl2ZVJvd11bJ2lkJ10sXG4gICAgICAgICAgICAgICAgICAgIGZpZWxkVmFsdWUgPSB0aGlzLnN0YXRlLmdyaWREYXRhW2FjdGl2ZVJvd11bYm91bmRGaWVsZF07XG4gICAgICAgICAgICAgICAgLy8g0L/QvtC70YPRh9C40YLRjCDQtNCw0L3QvdGL0LUg0L/QvtC70LXQuSDQuCDRg9GB0YLQsNC90L7QstC40YLRjCDRgdC+0YHRgtC+0Y/QvdC40LUg0LTQu9GPINCy0LjQtNC20LXRgtCwXG5cbiAgICAgICAgICAgICAgICAvLyDQv9C+0LrQsNC30LDRgtGMINC90L7QstC+0LUg0LfQvdCw0YfQtdC90LjQtVxuICAgICAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyB2YWx1ZTogdmFsdWUsIGZpZWxkVmFsdWU6IGZpZWxkVmFsdWUsIHNob3c6IGZhbHNlIH0pO1xuXG4gICAgICAgICAgICAgICAgLy8g0LLQtdGA0L3Rg9GC0Ywg0LfQvdCw0YfQtdC90LjQtSDQvdCw0LLQtdGA0YVcblxuICAgICAgICAgICAgICAgIGlmICh0aGlzLnByb3BzLm9uQ2hhbmdlKSB7XG4gICAgICAgICAgICAgICAgICAgIHRoaXMucHJvcHMub25DaGFuZ2UoYm91bmRGaWVsZERhdGEsIHZhbHVlKTtcblxuICAgICAgICAgICAgICAgICAgICAvLyB0ZXh0IHZhbHVlIG9mIGlucHV0XG4gICAgICAgICAgICAgICAgICAgIGlmIChib3VuZFRvRGF0YSkge1xuICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy5vbkNoYW5nZShib3VuZFRvRGF0YSwgZmllbGRWYWx1ZSk7XG4gICAgICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgICAgICAvL9C10YHQu9C4INC/0YDQuNCy0Y/Qt9Cw0L3QviDQtNGA0YPQs9C+0LUg0L/QvtC70LVcbiAgICAgICAgICAgICAgICAgICAgaWYgKHRoaXMucHJvcHMuY29sbE5hbWUpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMucHJvcHMub25DaGFuZ2UodGhpcy5wcm9wcy5jb2xsTmFtZSwgZmllbGRWYWx1ZSk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZUdyaWRDbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVHcmlkQ2xpY2soZXZlbnQsIHZhbHVlLCBhY3RpdmVSb3cpIHtcbiAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyBncmlkQWN0aXZlUm93OiBhY3RpdmVSb3cgfSk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2xvYWRMaWJzJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGxvYWRMaWJzKCkge1xuICAgICAgICAgICAgdmFyIF90aGlzMyA9IHRoaXM7XG5cbiAgICAgICAgICAgIHZhciBwb3N0VXJsID0gJy9uZXdBcGkvbG9hZExpYnMnO1xuICAgICAgICAgICAgdmFyIGxpYiA9IHRoaXMucHJvcHMubGliTmFtZTtcbiAgICAgICAgICAgIHZhciBzcWxXaGVyZSA9ICcnO1xuICAgICAgICAgICAgaWYgKHRoaXMucHJvcHMuc3FsRmllbGRzLmxlbmd0aCAmJiB0aGlzLnN0YXRlLmZpZWxkVmFsdWUpIHtcbiAgICAgICAgICAgICAgICB0aGlzLnByb3BzLnNxbEZpZWxkcy5mb3JFYWNoKGZ1bmN0aW9uIChmaWVsZCkge1xuICAgICAgICAgICAgICAgICAgICB2YXIgaXNPciA9IHNxbFdoZXJlLmxlbmd0aCA+IDAgPyAnIG9yICcgOiAnJztcbiAgICAgICAgICAgICAgICAgICAgc3FsV2hlcmUgPSBzcWxXaGVyZS5jb25jYXQoJyAnICsgaXNPciArICcgZW5jb2RlKCcgKyBmaWVsZCArICc6OmJ5dGVhLCBcXCdlc2NhcGVcXCcpIGlsaWtlIFxcJyUnICsgX3RoaXMzLnN0YXRlLmZpZWxkVmFsdWUudHJpbSgpICsgJyVcXCcnKTtcbiAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgICBzcWxXaGVyZSA9ICd3aGVyZSAnICsgc3FsV2hlcmU7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHZhciBsaWJQYXJhbXMgPSBzcWxXaGVyZS5sZW5ndGggPyB7IHNxbDogc3FsV2hlcmUgfSA6IHt9O1xuXG4gICAgICAgICAgICBmZXRjaERhdGEuZmV0Y2hEYXRhUG9zdChwb3N0VXJsICsgJy8nICsgbGliLCBsaWJQYXJhbXMpLnRoZW4oZnVuY3Rpb24gKHJlc3BvbnNlKSB7XG4gICAgICAgICAgICAgICAgaWYgKHJlc3BvbnNlICYmICdkYXRhJyBpbiByZXNwb25zZSkge1xuICAgICAgICAgICAgICAgICAgICB2YXIgZ3JpZERhdGEgPSByZXNwb25zZS5kYXRhLnJlc3VsdC5yZXN1bHQuZGF0YTtcbiAgICAgICAgICAgICAgICAgICAgX3RoaXMzLnNldFN0YXRlKHsgZ3JpZERhdGE6IGdyaWREYXRhIH0pO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0pLmNhdGNoKGZ1bmN0aW9uIChlcnJvcikge1xuICAgICAgICAgICAgICAgIGNvbnNvbGUuZXJyb3IoJ2xvYWRMaWJzIGVycm9yJywgZXJyb3IpO1xuICAgICAgICAgICAgICAgIHJlamVjdGVkKCk7XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBTZWxlY3REYXRhO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuU2VsZWN0RGF0YS5wcm9wVHlwZXMgPSB7XG4gICAgcmVhZE9ubHk6IFByb3BUeXBlcy5ib29sLFxuICAgIGRpc2FibGVkOiBQcm9wVHlwZXMuYm9vbCxcbiAgICBjb2xsSWQ6IFByb3BUeXBlcy5zdHJpbmcsXG4gICAgdGl0bGU6IFByb3BUeXBlcy5zdHJpbmcsXG4gICAgcGxhY2Vob2xkZXI6IFByb3BUeXBlcy5zdHJpbmcsXG4gICAgbmFtZTogUHJvcFR5cGVzLnN0cmluZy5pc1JlcXVpcmVkLFxuICAgIHNob3c6IFByb3BUeXBlcy5ib29sXG59O1xuXG5TZWxlY3REYXRhLmRlZmF1bHRQcm9wcyA9IHtcbiAgICByZWFkT25seTogZmFsc2UsXG4gICAgZGlzYWJsZWQ6IGZhbHNlLFxuICAgIGJ0bkRlbGV0ZTogZmFsc2UsXG4gICAgdmFsdWU6IDAsXG4gICAgY29sbElkOiAnaWQnLFxuICAgIHRpdGxlOiAnJyxcbiAgICBzaG93OiBmYWxzZVxufTtcblxubW9kdWxlLmV4cG9ydHMgPSBTZWxlY3REYXRhO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvY29tcG9uZW50cy9zZWxlY3QtZGF0YS9zZWxlY3QtZGF0YS5qc3hcbi8vIG1vZHVsZSBpZCA9IDI2N1xuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfID0gcmVxdWlyZSgnbG9kYXNoJyk7XG5cbi8vINC+0YHRg9GJ0LXRgdGC0LLQu9GP0LXRgiDRhNC40LvRjNGC0YDQsNGG0LjRjiDQv9C+INC30L3QsNGH0LXQvdC40LUg0Lgg0LjRidC10YIg0LLQviDQstGB0LXRhSDRgtC10LrRgdGC0L7QstGL0YUg0L/QvtC70Y/RhVxuXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uIChkYXRhLCBmaWx0ZXIpIHtcbiAgICB2YXIgcmVzdWx0ID0gZGF0YS5maWx0ZXIoZnVuY3Rpb24gKHJvdykge1xuXG4gICAgICAgIHJldHVybiAhIV8uZmluZChyb3csIGZ1bmN0aW9uICh2YWx1ZSwga2V5KSB7XG5cbiAgICAgICAgICAgIGlmICh0eXBlb2YgdmFsdWUgPT09ICdzdHJpbmcnICYmIHZhbHVlLmluY2x1ZGVzKGZpbHRlcikpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfSk7XG4gICAgfSk7XG4gICAgcmV0dXJuIHJlc3VsdDtcbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9saWJzL2dldERhdGFCeUZpbHRlci5qc1xuLy8gbW9kdWxlIGlkID0gMjY4XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgd3JhcHBlcjoge1xuICAgICAgICBtYXJnaW46ICc1cHgnLFxuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIHdpZHRoOiAnOTUlJ1xuXG4gICAgfSxcbiAgICBpbnB1dDoge1xuICAgICAgICB3aWR0aDogJzcwJScsXG4gICAgICAgIG1hcmdpbkxlZnQ6ICc1cHgnLFxuICAgICAgICBib3JkZXJSYWRpdXM6ICczcHgnXG5cbiAgICB9LFxuICAgIGhpZGU6IHtcbiAgICAgICAgZGlzcGxheTogJ25vbmUnXG4gICAgfSxcbiAgICBzZWxlY3Q6IHtcbiAgICAgICAgd2lkdGg6ICc2MCUnLFxuICAgICAgICBtYXJnaW5MZWZ0OiAnNXB4J1xuICAgIH0sXG4gICAgcmVhZE9ubHk6IHtcbiAgICAgICAgYmFja2dyb3VuZENvbG9yOiAnI0YzRUZFRidcbiAgICB9LFxuICAgIGxhYmVsOiB7XG4gICAgICAgIHdpZHRoOiAnMzAlJyxcbiAgICAgICAgbWFyZ2luOiAnNXB4J1xuICAgIH0sXG4gICAgYnV0dG9uOiB7XG4gICAgICAgIHdpZHRoOiAnMTAlJ1xuICAgIH1cblxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2NvbXBvbmVudHMvc2VsZWN0LWRhdGEvc2VsZWN0LWRhdGEtc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyNjlcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBkb2NSb3c6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAncm93J1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsdWUnXHJcbiAgICAgICAgKi9cbiAgICB9LFxuICAgIGRvY0NvbHVtbjoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nLFxuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIHllbGxvdycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgd2lkdGg6ICc1MCUnXG4gICAgfSxcbiAgICBkb2M6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJ1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJyb3duJ1xyXG4gICAgICAgICovXG4gICAgfSxcblxuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9LFxuXG4gICAgZ3JpZFJvdzoge1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsYWNrJyxcclxuICAgICAgICAqL1xuICAgICAgICBiYWNrZ3JvdW5kQ29sb3I6ICd3aGl0ZScsXG4gICAgICAgIHBvc2l0aW9uOiAncmVsYXRpdmUnLFxuICAgICAgICBtYXJnaW46ICcxMCUgMzAlIDEwJSAzMCUnLFxuICAgICAgICB3aWR0aDogJ2F1dG8nLFxuICAgICAgICBvcGFjaXR5OiAnMScsXG4gICAgICAgIHRvcDogJzEwMHB4J1xuICAgIH1cblxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvdmFuZW0vZG9jdW1lbnQvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyNzBcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgRG9jdW1lbnRSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jdW1lbnRzL2RvY3VtZW50cy5qc3gnKTtcbnZhciBzdHlsZXMgPSByZXF1aXJlKCcuL3N0eWxlcycpO1xudmFyIERPQ19UWVBFX0lEID0gJ1ZBTkVNJztcblxuLyoqXHJcbiAqINCa0LvQsNGB0YEg0YDQtdCw0LvQuNC30YPQtdGCINC00L7QutGD0LzQtdC90YIg0YHQv9GA0LDQstC+0YfQvdC40LrQsCDQv9GA0LjQt9C90LDQutC+0LIuXHJcbiAqL1xuXG52YXIgRG9jdW1lbnRzID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKERvY3VtZW50cywgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gRG9jdW1lbnRzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBEb2N1bWVudHMpO1xuXG4gICAgICAgIHJldHVybiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoRG9jdW1lbnRzLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoRG9jdW1lbnRzKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2N1bWVudHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFJlZ2lzdGVyLCB7IGluaXREYXRhOiB0aGlzLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgIHVzZXJEYXRhOiB0aGlzLnByb3BzLnVzZXJEYXRhLFxuICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSA/IHRoaXMucHJvcHMuaGlzdG9yeSA6IG51bGwsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnByb3BzLm1vZHVsZSxcbiAgICAgICAgICAgICAgICByZWY6ICdyZWdpc3RlcicsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiBET0NfVFlQRV9JRCxcbiAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLFxuICAgICAgICAgICAgICAgIHJlbmRlcjogdGhpcy5yZW5kZXJlciB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICdWYW5lbWF0ZSByZWdpc3RlciBzcGVjaWFsIHJlbmRlcidcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gRG9jdW1lbnRzO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxubW9kdWxlLmV4cG9ydHMgPSBEb2N1bWVudHM7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL3ZhbmVtL2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMjcxXG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgZ3JpZDoge1xuICAgICAgICBtYWluVGFibGU6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfSxcbiAgICAgICAgaGVhZGVyVGFibGU6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfSxcblxuICAgICAgICBncmlkQ29udGFpbmVyOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH1cblxuICAgIH1cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL3ZhbmVtL3N0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjcyXG4vLyBtb2R1bGUgY2h1bmtzID0gMCJdLCJtYXBwaW5ncyI6Ijs7Ozs7O0FBQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2hCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUM1SUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ3JPQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDcERBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDdERBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNoQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDek9BO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNyT0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDakJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDakNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNwREE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUN0REE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7OzsiLCJzb3VyY2VSb290IjoiIn0=