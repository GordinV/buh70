var lapsed =
webpackJsonp_name_([0],{

/***/ 0:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _docContext = __webpack_require__(1);

	var _docContext2 = _interopRequireDefault(_docContext);

	function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

	var ReactDOM = __webpack_require__(3);

	var _require = __webpack_require__(4),
	    BrowserRouter = _require.BrowserRouter;

	var Doc = __webpack_require__(48);


	initData = JSON.parse(initData);
	userData = JSON.parse(userData);

	_docContext2.default.initData = initData;
	_docContext2.default.userData = userData;
	_docContext2.default.module = 'lapsed';

	ReactDOM.hydrate(React.createElement(
	    BrowserRouter,
	    null,
	    React.createElement(Doc, { initData: initData,
	        userData: userData,
	        module: 'lapsed'
	    })
	), document.getElementById('doc'));

/***/ }),

/***/ 48:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);

	var Menu = __webpack_require__(49);
	var JournalDocument = __webpack_require__(167);

	var LapseDokument = __webpack_require__(219);
	var LasteRegister = __webpack_require__(221);

	var LasteTeenustRegister = __webpack_require__(228);
	var LapseKaartDokument = __webpack_require__(230);

	var LasteTaabelRegister = __webpack_require__(237);
	var LapseTaabelDokument = __webpack_require__(239);

	var VanemDokument = __webpack_require__(241);
	var VanemateRegister = __webpack_require__(243);

	var ArvedeRegister = __webpack_require__(245);
	var ArveDocument = __webpack_require__(247);

	var SmkRegister = __webpack_require__(250);
	var SmkDocument = __webpack_require__(252);

	var SorderideRegister = __webpack_require__(254);
	var SorderDocument = __webpack_require__(256);

	var AsutusRegister = __webpack_require__(258),
	    AsutusDocument = __webpack_require__(260);

	var NomRegister = __webpack_require__(262),
	    NomDocument = __webpack_require__(264);

	var TunnusRegister = __webpack_require__(266),
	    TunnusDocument = __webpack_require__(268);

	var _require = __webpack_require__(4),
	    Route = _require.Route,
	    withRouter = _require.withRouter,
	    Redirect = _require.Redirect;

	var _require2 = __webpack_require__(90),
	    StyleRoot = _require2.StyleRoot;

	var MODULE = 'Lapsed';
	var DocContext = __webpack_require__(1);

	var App = function (_React$Component) {
	    _inherits(App, _React$Component);

	    function App(props) {
	        _classCallCheck(this, App);

	        var _this = _possibleConstructorReturn(this, (App.__proto__ || Object.getPrototypeOf(App)).call(this, props));

	        _this.prepareParamsForToolbar = _this.prepareParamsForToolbar.bind(_this);
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
	                        return React.createElement(Menu, { params: btnParams,
	                            rekvId: DocContext.userData ? DocContext.userData.rekvid : 0,
	                            module: MODULE });
	                    }
	                }),
	                React.createElement(Route, { exact: true, path: '/lapsed',
	                    render: function render(props) {
	                        return React.createElement(LasteRegister, {
	                            history: props.history,
	                            initData: _this2.props.initData,
	                            module: MODULE });
	                    }
	                }),
	                React.createElement(Route, { exact: true, path: '/lapsed/laps',
	                    render: function render(props) {
	                        return React.createElement(LasteRegister, { history: props.history,
	                            initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/laps/:docId', component: LapseDokument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/vanem',
	                    render: function render(props) {
	                        return React.createElement(VanemateRegister, { history: props.history,
	                            initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/vanem/:docId', component: VanemDokument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/lapse_kaart',
	                    render: function render(props) {
	                        return React.createElement(LasteTeenustRegister, { history: props.history,
	                            initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/lapse_kaart/:docId', component: LapseKaartDokument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/lapse_taabel',
	                    render: function render(props) {
	                        return React.createElement(LasteTaabelRegister, { history: props.history,
	                            initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/lapse_taabel/:docId', component: LapseTaabelDokument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/arv',
	                    render: function render(props) {
	                        return React.createElement(ArvedeRegister, { history: props.history,
	                            initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/arv/:docId',
	                    render: function render(props) {
	                        return React.createElement(ArveDocument, _extends({}, props, { history: props.history }));
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/journal/:docId',
	                    render: function render(props) {
	                        return React.createElement(JournalDocument, _extends({}, props, { history: props.history }));
	                    }
	                }),
	                React.createElement(Route, { exact: true, path: '/lapsed/smk',
	                    render: function render(props) {
	                        return React.createElement(SmkRegister, { history: props.history,
	                            initData: _this2.props.initData,
	                            module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/smk/:docId', component: SmkDocument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/sorder',
	                    render: function render(props) {
	                        return React.createElement(SorderideRegister, {
	                            history: props.history,
	                            initData: _this2.props.initData,
	                            module: MODULE });
	                    }
	                }),
	                React.createElement(Route, { exact: true, path: '/lapsed/sorder/:docId', component: SorderDocument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/asutused/:docId', component: AsutusDocument, module: MODULE }),
	                React.createElement(Route, { exact: true, path: '/lapsed/asutused',
	                    render: function render(props) {
	                        return React.createElement(AsutusRegister, { history: props.history,
	                            initData: _this2.props.initData,
	                            module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/nomenclature',
	                    render: function render(props) {
	                        return React.createElement(NomRegister, { history: props.history,
	                            initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/nomenclature/:docId', component: NomDocument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/tunnus/:docId', component: TunnusDocument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/tunnus',
	                    render: function render(props) {
	                        return React.createElement(TunnusRegister, {
	                            module: MODULE,
	                            history: props.history,
	                            initData: _this2.props.initData });
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
	                var LapseDocument = __webpack_require__(219);
	                return React.createElement(LapseDocument, props);
	            };
	        }
	    }]);

	    return App;
	}(React.Component);

	module.exports = App;

/***/ }),

/***/ 219:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var DocContext = __webpack_require__(1);

	var PropTypes = __webpack_require__(32);
	var React = __webpack_require__(9);
	var _fetchData = __webpack_require__(50);
	var toolbarParams = {
	    btnAdd: {
	        show: true,
	        disabled: false
	    },
	    btnEdit: {
	        show: true,
	        disabled: false
	    },
	    btnDelete: {
	        show: false,
	        disabled: false
	    },
	    btnPrint: {
	        show: true,
	        disabled: false
	    }
	};

	var DocumentTemplate = __webpack_require__(168),
	    InputText = __webpack_require__(183),
	    InputNumber = __webpack_require__(187),
	    Select = __webpack_require__(192),
	    TextArea = __webpack_require__(194),
	    DataGrid = __webpack_require__(196),
	    relatedDocuments = __webpack_require__(217),
	    ModalPage = __webpack_require__(200),
	    styles = __webpack_require__(220);

	var LIBDOK = 'LAPS',
	    LIBRARIES = [];

	var now = new Date();

	var Laps = function (_React$PureComponent) {
	    _inherits(Laps, _React$PureComponent);

	    function Laps(props) {
	        _classCallCheck(this, Laps);

	        var _this = _possibleConstructorReturn(this, (Laps.__proto__ || Object.getPrototypeOf(Laps)).call(this, props));

	        _this.state = {
	            loadedData: false,
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            vanemId: null,
	            module: 'lapsed'
	        };

	        _this.renderer = _this.renderer.bind(_this);
	        _this.handlePageClick = _this.handlePageClick.bind(_this);
	        _this.handleGridBtnClick = _this.handleGridBtnClick.bind(_this);
	        _this.fetchData = _this.fetchData.bind(_this);

	        _this.docId = props.docId ? props.docId : Number(props.match.params.docId);

	        _this.pages = [{ pageName: 'Lapse kaart', docTypeId: 'LAPS' }, { pageName: 'Taabel', handlePageClick: _this.handlePageClick, docTypeId: 'LAPSE_TAABEL' }, { pageName: 'Arved', handlePageClick: _this.handlePageClick, docTypeId: 'ARV' }, { pageName: 'Maksekoraldused', handlePageClick: _this.handlePageClick, docTypeId: 'SMK' }, { pageName: 'Kassaorderid', handlePageClick: _this.handlePageClick, docTypeId: 'SORDER' }];
	        return _this;
	    }

	    _createClass(Laps, [{
	        key: 'componentDidMount',
	        value: function componentDidMount() {
	            if (this.props.history && this.props.history.location.state) {
	                var vanemId = this.props.history.location.state.vanemId;
	                var _module = this.props.history.location.state.module ? this.props.history.location.state.module : 'lapsed';
	                this.setState({ vanemId: vanemId, module: _module });
	            }
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var initData = this.props.initData ? this.props.initData : {};

	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                module: this.state.module,
	                docTypeId: 'LAPS',
	                initData: initData,
	                libs: LIBRARIES,
	                pages: this.pages,
	                renderer: this.renderer,
	                handleGridBtnClick: this.handleGridBtnClick,
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

	            if (self.docData.id == 0) {
	                //neew record
	                self.docData.vanemid = this.state.vanemId;
	            }

	            var doc = this.refs['document'];
	            var libs = doc ? doc.libs : {};

	            if (!this.docId && self.docData.id) {
	                this.docId = self.docData.id;
	            }

	            return React.createElement(
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
	                            maxLength: '11',
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
	                        toolbarParams: toolbarParams,
	                        handleGridBtnClick: self.handleGridBtnClick,
	                        readOnly: !isEditMode,
	                        style: styles.grid.headerTable,
	                        docTypeId: 'vanem',
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
	                        handleGridBtnClick: self.handleGridBtnClick,
	                        docTypeId: 'lapse_kaart',
	                        readOnly: !isEditMode,
	                        style: styles.grid.headerTable,
	                        ref: 'teenuste-data-grid' })
	                )
	            );
	        }
	    }, {
	        key: 'handlePageClick',
	        value: function handlePageClick(pageDocTypeId) {
	            // данные для фильтра
	            var isikukood = this.refs['document'].docData.isikukood;

	            this.props.history.push({
	                pathname: '/lapsed/' + pageDocTypeId,
	                state: { isikukood: isikukood, type: 'text' }
	            });
	        }

	        // обработчик события клик на гриде родителей

	    }, {
	        key: 'handleGridBtnClick',
	        value: function handleGridBtnClick(btnName, activeRow, id, docTypeId) {
	            var _this2 = this;

	            switch (btnName) {
	                case "edit":

	                    this.props.history.push({
	                        pathname: '/lapsed/' + docTypeId + '/' + id,
	                        state: { lapsId: this.docId, module: this.state.module }
	                    });
	                    break;
	                case "add":
	                    this.props.history.push({
	                        pathname: '/lapsed/' + docTypeId + '/0',
	                        state: { lapsId: this.docId, module: this.state.module }
	                    });
	                    break;
	                case "delete":
	                    //send post to delete row
	                    this.fetchData(docTypeId, id).then(function (response) {

	                        var current = _this2.props.location.pathname;
	                        _this2.props.history.replace('/reload');
	                        setTimeout(function () {
	                            _this2.props.history.replace(current);
	                        });
	                    });
	                    break;
	                default:
	                    console.log('Vigane click');
	            }
	        }

	        // отправит запрос на удаление с параметром тип документа и ид

	    }, {
	        key: 'fetchData',
	        value: function fetchData(docTypeId, id) {

	            var url = '/newApi/delete';

	            var params = {
	                parameter: docTypeId,
	                module: 'lapsed',
	                userId: DocContext.userData.userId,
	                uuid: DocContext.userData.uuid,
	                docId: id
	            };

	            return _fetchData['fetchDataPost'](url, params);
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

/***/ 220:
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

/***/ 221:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(222);
	var styles = __webpack_require__(227);
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

/***/ 227:
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

/***/ 228:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(222);
	var styles = __webpack_require__(229);
	var DOC_TYPE_ID = 'LAPSE_KAART';

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
	                'Lapse teenuste register special render'
	            );
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 229:
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

/***/ 230:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(32);
	var React = __webpack_require__(9);

	var DocumentTemplate = __webpack_require__(168),
	    InputText = __webpack_require__(183),
	    InputNumber = __webpack_require__(187),
	    ButtonEdit = __webpack_require__(175),
	    InputDate = __webpack_require__(185),
	    Select = __webpack_require__(192),
	    CheckBox = __webpack_require__(231),
	    SelectData = __webpack_require__(233),
	    TextArea = __webpack_require__(194),
	    DataGrid = __webpack_require__(196),
	    ModalPage = __webpack_require__(200),
	    styles = __webpack_require__(236);

	var LIBDOK = 'LAPSE_KAART',
	    LIBRARIES = [{ id: 'tunnus', filter: '' }, {
	    id: 'nomenclature',
	    filter: 'where dok = \'ARV\''
	}];

	var now = new Date();

	var Laps = function (_React$PureComponent) {
	    _inherits(Laps, _React$PureComponent);

	    function Laps(props) {
	        _classCallCheck(this, Laps);

	        var _this = _possibleConstructorReturn(this, (Laps.__proto__ || Object.getPrototypeOf(Laps)).call(this, props));

	        _this.state = {
	            loadedData: false,
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            module: 'lapsed'
	        };
	        //        lapsId: props.lapsId ? props.lapsId : props.match.params.lapsId ? Number(props.match.params.lapsId) : 0

	        _this.renderer = _this.renderer.bind(_this);
	        _this.handlePageClick = _this.handlePageClick.bind(_this);
	        _this.handleGridBtnClick = _this.handleGridBtnClick.bind(_this);
	        _this.btnEditNomClick = _this.btnEditNomClick.bind(_this);
	        _this.btnEditLapsClick = _this.btnEditLapsClick.bind(_this);

	        _this.pages = [{ pageName: 'Teenus', docTypeId: 'LAPSE_KAART' }];
	        return _this;
	    }

	    _createClass(Laps, [{
	        key: 'componentDidMount',
	        value: function componentDidMount() {
	            var lapsId = void 0;
	            if (this.props.history && this.props.history.location.state) {
	                lapsId = this.props.history.location.state.lapsId;
	                this.setState({ lapsId: lapsId });
	            }
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var initData = this.props.initData ? this.props.initData : {};

	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                module: this.state.module,
	                docTypeId: 'LAPSE_KAART',
	                userData: this.props.userData,
	                initData: initData,
	                libs: LIBRARIES,
	                pages: this.pages,
	                renderer: this.renderer,
	                handleGridBtnClick: this.handleGridBtnClick,
	                history: this.props.history,
	                focusElement: 'input-kood'
	            });
	        }

	        /**
	         *Вернет кастомные компоненты документа
	         */

	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            var bpm = self.docData && self.docData.bpm ? self.docData.bpm : [],
	                isEditMode = self.state.edited;

	            if ((self.docData.id == 0 || !self.docData.parentid) && this.state.lapsId) {
	                //new record
	                self.docData.parentid = this.state.lapsId;
	            }

	            var buttonEditNom = styles.btnEditNom;

	            return React.createElement(
	                'div',
	                { style: styles.doc },
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(SelectData, { title: 'Lapse nimi:',
	                            name: 'parentid',
	                            userData: self.userData,
	                            libName: 'laps',
	                            sqlFields: ['nimi', 'isikukood'],
	                            data: [],
	                            value: self.docData.parentid || 0,
	                            defaultValue: self.docData.lapse_nimi,
	                            boundToGrid: 'nimi',
	                            boundToData: 'lapse_nimi',
	                            ref: 'select-parentid',
	                            btnDelete: false,
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(ButtonEdit, {
	                            ref: 'btnEdit',
	                            onClick: this.btnEditLapsClick,
	                            show: !isEditMode,
	                            style: buttonEditNom,
	                            disabled: false
	                        })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(Select, { title: 'Kood:',
	                            name: 'nomid',
	                            libs: 'nomenclature',
	                            data: self.libs['nomenclature'],
	                            value: self.docData.nomid || 0,
	                            defaultValue: self.docData.kood,
	                            ref: 'select-nomid',
	                            collId: 'id',
	                            btnDelete: isEditMode,
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(ButtonEdit, {
	                            ref: 'btnEdit',
	                            onClick: this.btnEditNomClick,
	                            show: !isEditMode,
	                            disabled: false,
	                            style: buttonEditNom
	                        })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(InputNumber, { ref: 'input-hind',
	                            title: 'Hind:',
	                            name: 'hind',
	                            value: Number(self.docData.hind) || 0,
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputText, { title: '\xDCksus:',
	                            name: 'yksus',
	                            value: self.docData.yksus || '',
	                            ref: 'input-yksus',
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange }),
	                        React.createElement(Select, { title: 'Tunnus:',
	                            name: 'tunnus',
	                            libs: 'tunnus',
	                            data: self.libs['tunnus'],
	                            value: self.docData.tunnus || '',
	                            defaultValue: self.docData.tunnus || '',
	                            ref: 'select-tunnus',
	                            collId: 'kood',
	                            btnDelete: isEditMode,
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
	                        }),
	                        React.createElement(CheckBox, { title: 'Kas arvesta eraldi?',
	                            name: 'kas_eraldi',
	                            value: Boolean(self.docData.kas_eraldi),
	                            ref: 'checkbox_kas_eraldi',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
	                        }),
	                        React.createElement(CheckBox, { title: 'Kas ettemaks?',
	                            name: 'kas_ettemaks',
	                            value: Boolean(self.docData.kas_ettemaks),
	                            ref: 'checkbox_kas_ettemaks',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
	                        })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(InputNumber, { ref: 'input-soodus',
	                            title: 'Soodustus:',
	                            name: 'soodus',
	                            value: Number(self.docData.soodus) || 0,
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputDate, { title: 'Kehtib alates:',
	                            name: 'sooduse_alg',
	                            value: self.docData.sooduse_alg || '',
	                            ref: 'input-soodus_alg',
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputDate, { title: 'Kehtib kuni:',
	                            name: 'sooduse_lopp',
	                            value: self.docData.sooduse_lopp || '',
	                            ref: 'input-soodus_lopp',
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange })
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
	                )
	            );
	        }
	    }, {
	        key: 'handlePageClick',
	        value: function handlePageClick(pageDocTypeId) {
	            //        document.location.href = `/lapsed/${pageDocTypeId}/`;//@todo Обновить
	            this.props.history.push('/lapsed/' + pageDocTypeId);
	        }

	        // обработчик события клик на гриде родителей

	    }, {
	        key: 'handleGridBtnClick',
	        value: function handleGridBtnClick(btnName, activeRow, id, docTypeId) {
	            switch (btnName) {
	                case "edit":
	                    this.props.history.push('/lapsed/' + docTypeId + '/' + id);
	                    break;
	                case "add":
	                    this.props.history.push('/lapsed/' + docTypeId + '/0/' + this.state.docId);
	                    break;
	                case "delete":
	                    console.log('btnDelete clicked');
	                    break;
	                default:
	                    console.log('Vigane click');
	            }
	        }

	        //обработчик события по клику кнопки Редактирование сноменклатуры

	    }, {
	        key: 'btnEditNomClick',
	        value: function btnEditNomClick() {
	            var docNomId = this.refs['document'].docData.nomid;

	            // осуществит переход на карточку контр-агента
	            this.props.history.push('/lapsed/nomenclature/' + docNomId);
	        }

	        //обработчик события по клику кнопки Редактирование ребенка

	    }, {
	        key: 'btnEditLapsClick',
	        value: function btnEditLapsClick() {
	            var docLapsId = this.refs['document'].docData.parentid;

	            // осуществит переход на карточку контр-агента
	            this.props.history.push({
	                pathname: '/lapsed/laps/' + docLapsId,
	                state: { teenusId: this.state.docId, module: this.state.module }
	            });
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

/***/ 231:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(32);
	var radium = __webpack_require__(90);

	var React = __webpack_require__(9),
	    styles = __webpack_require__(232);

	var Input = function (_React$PureComponent) {
	    _inherits(Input, _React$PureComponent);

	    function Input(props) {
	        _classCallCheck(this, Input);

	        var _this = _possibleConstructorReturn(this, (Input.__proto__ || Object.getPrototypeOf(Input)).call(this, props));

	        _this.state = {
	            value: Boolean(props.value),
	            readOnly: props.readOnly,
	            disabled: props.disabled
	        };
	        _this.onChange = _this.onChange.bind(_this);
	        return _this;
	    }

	    // will update state if props changed


	    _createClass(Input, [{
	        key: 'componentDidMount',
	        value: function componentDidMount() {
	            this.refs['checkbox'].checked = this.state.value;
	        }
	    }, {
	        key: 'onChange',
	        value: function onChange(e) {
	            var value = e.target.checked;

	            this.setState({ value: value });

	            if (!this.state.readOnly && this.props.onChange) {
	                this.props.onChange(this.props.name, value);
	            }
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var inputStyle = Object.assign({}, styles.input, this.props.width ? { width: this.props.width } : {}, this.state.readOnly ? styles.readOnly : {});

	            return React.createElement(
	                'div',
	                { style: styles.wrapper },
	                React.createElement(
	                    'label',
	                    { style: styles.label, htmlFor: this.props.name, ref: 'label' },
	                    this.props.title
	                ),
	                React.createElement('input', { type: 'checkbox',
	                    id: this.props.name,
	                    ref: 'checkbox',
	                    style: inputStyle,
	                    name: this.props.name,
	                    value: this.state.value,
	                    checked: this.state.value,
	                    readOnly: this.state.readOnly,
	                    onChange: this.onChange,
	                    disabled: this.state.readOnly
	                })
	            );
	        }

	        /**
	         * установит фокус на элементы
	         */

	    }, {
	        key: 'focus',
	        value: function focus() {
	            this.refs['checkbox'].focus();
	        }
	    }], [{
	        key: 'getDerivedStateFromProps',
	        value: function getDerivedStateFromProps(nextProps, prevState) {
	            if (nextProps.value !== prevState.value || nextProps.readOnly !== prevState.readOnly) {
	                return { value: nextProps.value, readOnly: nextProps.readOnly };
	            } else return null;
	        }
	    }]);

	    return Input;
	}(React.PureComponent);

	Input.propTypes = {
	    name: PropTypes.string.isRequired,
	    value: PropTypes.bool,
	    readOnly: PropTypes.bool,
	    disabled: PropTypes.bool,
	    title: PropTypes.string
	};

	Input.defaultProps = {
	    readOnly: false,
	    disabled: false,
	    value: false,
	    title: ''
	};

	module.exports = radium(Input);

/***/ }),

/***/ 232:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    input: {
	        ':focus': {
	            backgroundColor: 'lightpink'
	        }
	    },
	    readOnly: {
	        backgroundColor: '#F3EFEF'
	    },
	    wrapper: {
	        margin: '5px',
	        display: 'flex',
	        width: '95%'
	    },
	    label: {
	        width: '30%',
	        margin: '5px'
	    }
	};

/***/ }),

/***/ 236:
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
	    },

	    btnEditNom: {
	        width: 'min-content'
	    },

	    selectNom: {
	        marginLeft: '10px'
	    }

	};

/***/ }),

/***/ 237:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(222);
	var styles = __webpack_require__(238);
	var DOC_TYPE_ID = 'LAPSE_TAABEL';

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
	                'Lapse taabel register special render'
	            );
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 238:
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

/***/ 239:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(32);
	var React = __webpack_require__(9);

	var DocumentTemplate = __webpack_require__(168),
	    InputText = __webpack_require__(183),
	    InputNumber = __webpack_require__(187),
	    ButtonEdit = __webpack_require__(175),
	    InputDate = __webpack_require__(185),
	    Select = __webpack_require__(192),
	    SelectData = __webpack_require__(233),
	    TextArea = __webpack_require__(194),
	    DataGrid = __webpack_require__(196),
	    ModalPage = __webpack_require__(200),
	    styles = __webpack_require__(240);

	var LIBDOK = 'LAPSE_TAABEL',
	    LIBRARIES = [{ id: 'lapse_kaart', filter: '' }];

	var now = new Date();

	var Laps = function (_React$PureComponent) {
	    _inherits(Laps, _React$PureComponent);

	    function Laps(props) {
	        _classCallCheck(this, Laps);

	        var _this = _possibleConstructorReturn(this, (Laps.__proto__ || Object.getPrototypeOf(Laps)).call(this, props));

	        _this.state = {
	            module: 'lapsed',
	            loadedData: false,
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            lapsId: props.lapsId ? props.lapsId : props.match.params.paramId ? Number(props.match.params.paramId) : 0
	        };

	        _this.renderer = _this.renderer.bind(_this);
	        _this.handlePageClick = _this.handlePageClick.bind(_this);
	        _this.handleGridBtnClick = _this.handleGridBtnClick.bind(_this);
	        _this.btnEditNomClick = _this.btnEditNomClick.bind(_this);
	        _this.btnEditLapsClick = _this.btnEditLapsClick.bind(_this);

	        _this.pages = [{ pageName: 'Lapse taabel', docTypeId: 'LAPSE_TAABEL' }];
	        return _this;
	    }

	    _createClass(Laps, [{
	        key: 'render',
	        value: function render() {

	            var initData = this.props.initData ? this.props.initData : {};

	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'LAPSE_TAABEL',
	                module: this.state.module,
	                initData: initData,
	                libs: LIBRARIES,
	                pages: this.pages,
	                renderer: this.renderer,
	                handleGridBtnClick: this.handleGridBtnClick,
	                history: this.props.history,
	                focusElement: 'input-kood'
	            });
	        }

	        /**
	         *Вернет кастомные компоненты документа
	         */

	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            var bpm = self.docData && self.docData.bpm ? self.docData.bpm : [],
	                isEditMode = self.state.edited;

	            if ((self.docData.id == 0 || !self.docData.parentid) && this.state.lapsId) {
	                //new record
	                self.docData.parentid = this.state.lapsId;
	            }

	            var kpv = new Date(),
	                kuu = kpv.getMonth(),
	                aasta = kpv.getFullYear();

	            var buttonEditNom = styles.btnEditNom;

	            return React.createElement(
	                'div',
	                { style: styles.doc },
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(SelectData, { title: 'Lapse nimi:',
	                            name: 'parentid',
	                            libName: 'laps',
	                            sqlFields: ['nimi', 'isikukood'],
	                            data: [],
	                            value: self.docData.parentid || 0,
	                            defaultValue: self.docData.nimi,
	                            boundToGrid: 'nimi',
	                            boundToData: 'nimi',
	                            ref: 'select-parentid',
	                            btnDelete: false,
	                            userData: self.userData,
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(ButtonEdit, {
	                            ref: 'btnEdit',
	                            onClick: this.btnEditLapsClick,
	                            show: !isEditMode,
	                            style: buttonEditNom,
	                            disabled: false
	                        })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(Select, { title: 'Kood:',
	                            name: 'nomid',
	                            libs: 'lapse_kaart',
	                            data: self.libs['lapse_kaart'],
	                            value: self.docData.nomid || 0,
	                            defaultValue: self.docData.kood,
	                            ref: 'select-nomid',
	                            btnDelete: isEditMode,
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(ButtonEdit, {
	                            ref: 'btnEdit',
	                            onClick: this.btnEditNomClick,
	                            show: !isEditMode,
	                            style: buttonEditNom,
	                            disabled: false
	                        })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(InputNumber, { ref: 'input-kogus',
	                            title: 'Kogus:',
	                            name: 'kogus',
	                            value: Number(self.docData.kogus) || Number(null),
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputNumber, { ref: 'input-kuu',
	                            title: 'Kuu:',
	                            name: 'kuu',
	                            value: Number(self.docData.kuu) || Number(kuu),
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputNumber, { ref: 'input-aasta',
	                            title: 'Aasta:',
	                            name: 'aasta',
	                            value: Number(self.docData.aasta) || Number(aasta),
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange })
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
	                )
	            );
	        }
	    }, {
	        key: 'handlePageClick',
	        value: function handlePageClick(pageDocTypeId) {
	            //        document.location.href = `/lapsed/${pageDocTypeId}/`;//@todo Обновить
	            this.props.history.push('/lapsed/' + pageDocTypeId);
	        }

	        // обработчик события клик на гриде родителей

	    }, {
	        key: 'handleGridBtnClick',
	        value: function handleGridBtnClick(btnName, activeRow, id, docTypeId) {
	            switch (btnName) {
	                case "edit":
	                    this.props.history.push('/lapsed/' + docTypeId + '/' + id + '/0');
	                    break;
	                case "add":
	                    this.props.history.push('/lapsed/' + docTypeId + '/0/' + this.state.docId);
	                    break;
	                default:
	                    console.log('Vigane click');
	            }
	        }

	        //обработчик события по клику кнопки Редактирование сноменклатуры

	    }, {
	        key: 'btnEditNomClick',
	        value: function btnEditNomClick() {
	            var docNomId = this.refs['document'].docData.nomid;

	            // осуществит переход на карточку контр-агента
	            this.props.history.push('/lapsed/nomenclature/' + docNomId);
	        }

	        //обработчик события по клику кнопки Редактирование ребенка

	    }, {
	        key: 'btnEditLapsClick',
	        value: function btnEditLapsClick() {
	            var docLapsId = this.refs['document'].docData.parentid;

	            // осуществит переход на карточку контр-агента
	            this.props.history.push('/lapsed/laps/' + docLapsId);
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

/***/ 240:
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
	    },

	    btnEditNom: {
	        width: 'min-content'
	    }

	};

/***/ }),

/***/ 241:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(32);
	var React = __webpack_require__(9);

	var DocumentTemplate = __webpack_require__(168),
	    InputText = __webpack_require__(183),
	    Select = __webpack_require__(192),
	    ButtonEdit = __webpack_require__(175),
	    SelectData = __webpack_require__(233),
	    TextArea = __webpack_require__(194),
	    DataGrid = __webpack_require__(196),
	    ModalPage = __webpack_require__(200),
	    styles = __webpack_require__(242);

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
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            lapsId: null,
	            module: 'lapsed'
	        };

	        _this.renderer = _this.renderer.bind(_this);
	        _this.handlePageClick = _this.handlePageClick.bind(_this);
	        _this.handleLasteGridBtnClick = _this.handleLasteGridBtnClick.bind(_this);
	        _this.btnEditAsutusClick = _this.btnEditAsutusClick.bind(_this);

	        _this.pages = [{ pageName: 'Vanem kaart', docTypeId: 'VANEM' }, { pageName: 'Arved', handlePageClick: _this.handlePageClick, docTypeId: 'ARV' }, { pageName: 'Maksekoraldused', handlePageClick: _this.handlePageClick, docTypeId: 'SMK' }, { pageName: 'Kassaorderid', handlePageClick: _this.handlePageClick, docTypeId: 'SORDER' }];
	        return _this;
	    }

	    _createClass(Vanem, [{
	        key: 'componentDidMount',
	        value: function componentDidMount() {
	            if (this.props.history && this.props.history.location.state) {
	                var lapsId = this.props.history.location.state.lapsId;
	                var _module = this.props.history.location.state.module;
	                this.setState({ lapsId: lapsId, module: _module });
	            }
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var initData = this.props.initData ? this.props.initData : {};

	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'VANEM',
	                module: this.state.module,
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

	            if (this.state.lapsId) {
	                self.docData.parentid = this.state.lapsId;
	            }

	            return React.createElement(
	                'div',
	                { style: styles.doc },
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(SelectData, { title: 'Vanem:',
	                            name: 'asutusid',
	                            libName: 'asutused',
	                            sqlFields: ['nimetus', 'regkood'],
	                            data: [],
	                            value: self.docData.asutusid || 0,
	                            defaultValue: self.docData.vanem_nimi,
	                            boundToGrid: 'nimetus',
	                            boundToData: 'vanem_nimi',
	                            ref: 'select-asutusid',
	                            btnDelete: false,
	                            userData: self.userData,
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(ButtonEdit, {
	                            ref: 'btnEdit',
	                            onClick: this.btnEditAsutusClick,
	                            show: !isEditMode,
	                            style: styles.btnEdit,
	                            disabled: false
	                        })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
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
	                        docTypeId: 'laps',
	                        ref: 'laspsed-data-grid' })
	                )
	            );
	        }
	    }, {
	        key: 'handlePageClick',
	        value: function handlePageClick(pageDocTypeId) {
	            var nimi = this.refs['document'].docData.vanem_nimi;

	            this.props.history.push({
	                pathname: '/lapsed/' + pageDocTypeId,
	                state: { asutus: nimi, type: 'text' }
	            });
	        }
	    }, {
	        key: 'handleLasteGridBtnClick',
	        value: function handleLasteGridBtnClick(btnName, activeRow, id, docTypeId) {

	            switch (btnName) {
	                case "edit":
	                    this.props.history.push({
	                        pathname: '/lapsed/' + docTypeId + '/' + id,
	                        state: { vanemId: this.state.docId, module: this.state.module }
	                    });

	                    break;
	                case "add":
	                    this.props.history.push({
	                        pathname: '/lapsed/' + docTypeId + '/0',
	                        state: { vanemId: this.state.docId, module: this.state.module }
	                    });
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

/***/ 242:
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
	    },

	    btnEdit: {
	        width: 'min-content'
	    }

	};

/***/ }),

/***/ 243:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(222);
	var styles = __webpack_require__(244);
	var DOC_TYPE_ID = 'VANEM';
	var toolbarParams = {
	    btnAdd: {
	        show: false,
	        disabled: false
	    },
	    btnEdit: {
	        show: true,
	        disabled: false
	    },
	    btnDelete: {
	        show: true,
	        disabled: false
	    },
	    btnPrint: {
	        show: true,
	        disabled: false
	    }
	};

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
	                toolbarParams: toolbarParams,
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

/***/ 244:
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
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibGFwc2VkLmpzIiwic291cmNlcyI6WyJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvbGFwc2VkLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL21vZHVsZXMvbGFwc2VkLmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHMvZG9jdW1lbnQvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwcy9kb2N1bWVudC9sYXBzLnN0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHMvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwcy9sYXBzLXJlZ2lzdGVyLXN0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHNlX2thYXJ0L2luZGV4LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHNlX2thYXJ0L3N0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHNlX2thYXJ0L2RvY3VtZW50L2luZGV4LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9jb21wb25lbnRzL2lucHV0LWNoZWNrYm94L2lucHV0LWNoZWNrYm94LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9jb21wb25lbnRzL2lucHV0LWNoZWNrYm94L3N0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHNlX2thYXJ0L2RvY3VtZW50L3N0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHNlX3RhYWJlbC9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9sYXBzZV90YWFiZWwvc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwc2VfdGFhYmVsL2RvY3VtZW50L2luZGV4LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHNlX3RhYWJlbC9kb2N1bWVudC9zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy92YW5lbS9kb2N1bWVudC9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy92YW5lbS9kb2N1bWVudC9zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy92YW5lbS9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy92YW5lbS9zdHlsZXMuanMiXSwic291cmNlc0NvbnRlbnQiOlsiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2RvY0NvbnRleHQgPSByZXF1aXJlKCcuL2RvYy1jb250ZXh0LmpzJyk7XG5cbnZhciBfZG9jQ29udGV4dDIgPSBfaW50ZXJvcFJlcXVpcmVEZWZhdWx0KF9kb2NDb250ZXh0KTtcblxuZnVuY3Rpb24gX2ludGVyb3BSZXF1aXJlRGVmYXVsdChvYmopIHsgcmV0dXJuIG9iaiAmJiBvYmouX19lc01vZHVsZSA/IG9iaiA6IHsgZGVmYXVsdDogb2JqIH07IH1cblxudmFyIFJlYWN0RE9NID0gcmVxdWlyZSgncmVhY3QtZG9tJyk7XG5cbnZhciBfcmVxdWlyZSA9IHJlcXVpcmUoJ3JlYWN0LXJvdXRlci1kb20nKSxcbiAgICBCcm93c2VyUm91dGVyID0gX3JlcXVpcmUuQnJvd3NlclJvdXRlcjtcblxudmFyIERvYyA9IHJlcXVpcmUoJy4uL2Zyb250ZW5kL21vZHVsZXMvbGFwc2VkLmpzeCcpO1xuXG5cbmluaXREYXRhID0gSlNPTi5wYXJzZShpbml0RGF0YSk7XG51c2VyRGF0YSA9IEpTT04ucGFyc2UodXNlckRhdGEpO1xuXG5fZG9jQ29udGV4dDIuZGVmYXVsdC5pbml0RGF0YSA9IGluaXREYXRhO1xuX2RvY0NvbnRleHQyLmRlZmF1bHQudXNlckRhdGEgPSB1c2VyRGF0YTtcbl9kb2NDb250ZXh0Mi5kZWZhdWx0Lm1vZHVsZSA9ICdsYXBzZWQnO1xuXG5SZWFjdERPTS5oeWRyYXRlKFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgQnJvd3NlclJvdXRlcixcbiAgICBudWxsLFxuICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jLCB7IGluaXREYXRhOiBpbml0RGF0YSxcbiAgICAgICAgdXNlckRhdGE6IHVzZXJEYXRhLFxuICAgICAgICBtb2R1bGU6ICdsYXBzZWQnXG4gICAgfSlcbiksIGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCdkb2MnKSk7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9sYXBzZWQuanNcbi8vIG1vZHVsZSBpZCA9IDBcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2V4dGVuZHMgPSBPYmplY3QuYXNzaWduIHx8IGZ1bmN0aW9uICh0YXJnZXQpIHsgZm9yICh2YXIgaSA9IDE7IGkgPCBhcmd1bWVudHMubGVuZ3RoOyBpKyspIHsgdmFyIHNvdXJjZSA9IGFyZ3VtZW50c1tpXTsgZm9yICh2YXIga2V5IGluIHNvdXJjZSkgeyBpZiAoT2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsKHNvdXJjZSwga2V5KSkgeyB0YXJnZXRba2V5XSA9IHNvdXJjZVtrZXldOyB9IH0gfSByZXR1cm4gdGFyZ2V0OyB9O1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG5cbnZhciBNZW51ID0gcmVxdWlyZSgnLi8uLi9jb21wb25lbnRzL21lbnUtdG9vbGJhci9tZW51LXRvb2xiYXIuanN4Jyk7XG52YXIgSm91cm5hbERvY3VtZW50ID0gcmVxdWlyZSgnLi4vZG9jcy9qb3VybmFsL2RvY3VtZW50L2luZGV4LmpzeCcpO1xuXG52YXIgTGFwc2VEb2t1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9sYXBzL2RvY3VtZW50L2luZGV4LmpzeCcpO1xudmFyIExhc3RlUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3MvbGFwcy9pbmRleC5qc3gnKTtcblxudmFyIExhc3RlVGVlbnVzdFJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL2xhcHNlX2thYXJ0L2luZGV4LmpzeCcpO1xudmFyIExhcHNlS2FhcnREb2t1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9sYXBzZV9rYWFydC9kb2N1bWVudC9pbmRleC5qc3gnKTtcblxudmFyIExhc3RlVGFhYmVsUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3MvbGFwc2VfdGFhYmVsL2luZGV4LmpzeCcpO1xudmFyIExhcHNlVGFhYmVsRG9rdW1lbnQgPSByZXF1aXJlKCcuLy4uL2RvY3MvbGFwc2VfdGFhYmVsL2RvY3VtZW50L2luZGV4LmpzeCcpO1xuXG52YXIgVmFuZW1Eb2t1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy92YW5lbS9kb2N1bWVudC9pbmRleC5qc3gnKTtcbnZhciBWYW5lbWF0ZVJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL3ZhbmVtL2luZGV4LmpzeCcpO1xuXG52YXIgQXJ2ZWRlUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3MvYXJ2L2luZGV4LmpzeCcpO1xudmFyIEFydmVEb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9hcnYvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG5cbnZhciBTbWtSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9zbWsvaW5kZXguanN4Jyk7XG52YXIgU21rRG9jdW1lbnQgPSByZXF1aXJlKCcuLy4uL2RvY3Mvc21rL2RvY3VtZW50L2luZGV4LmpzeCcpO1xuXG52YXIgU29yZGVyaWRlUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3Mvc29yZGVyL2luZGV4LmpzeCcpO1xudmFyIFNvcmRlckRvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL3NvcmRlci9kb2N1bWVudC9pbmRleC5qc3gnKTtcblxudmFyIEFzdXR1c1JlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL2FzdXR1c2VkL2luZGV4LmpzeCcpLFxuICAgIEFzdXR1c0RvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2FzdXR1c2VkL2RvY3VtZW50L2luZGV4LmpzeCcpO1xuXG52YXIgTm9tUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3Mvbm9tZW5jbGF0dXJlL2luZGV4LmpzeCcpLFxuICAgIE5vbURvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL25vbWVuY2xhdHVyZS9kb2N1bWVudC9pbmRleC5qc3gnKTtcblxudmFyIFR1bm51c1JlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL3R1bm51cy9pbmRleC5qc3gnKSxcbiAgICBUdW5udXNEb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy90dW5udXMvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG5cbnZhciBfcmVxdWlyZSA9IHJlcXVpcmUoJ3JlYWN0LXJvdXRlci1kb20nKSxcbiAgICBSb3V0ZSA9IF9yZXF1aXJlLlJvdXRlLFxuICAgIHdpdGhSb3V0ZXIgPSBfcmVxdWlyZS53aXRoUm91dGVyLFxuICAgIFJlZGlyZWN0ID0gX3JlcXVpcmUuUmVkaXJlY3Q7XG5cbnZhciBfcmVxdWlyZTIgPSByZXF1aXJlKCdyYWRpdW0nKSxcbiAgICBTdHlsZVJvb3QgPSBfcmVxdWlyZTIuU3R5bGVSb290O1xuXG52YXIgTU9EVUxFID0gJ0xhcHNlZCc7XG52YXIgRG9jQ29udGV4dCA9IHJlcXVpcmUoJy4vLi4vZG9jLWNvbnRleHQuanMnKTtcblxudmFyIEFwcCA9IGZ1bmN0aW9uIChfUmVhY3QkQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKEFwcCwgX1JlYWN0JENvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBBcHAocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIEFwcCk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKEFwcC5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKEFwcCkpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5wcmVwYXJlUGFyYW1zRm9yVG9vbGJhciA9IF90aGlzLnByZXBhcmVQYXJhbXNGb3JUb29sYmFyLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5jb21wb25ldHMgPSB7fTtcbiAgICAgICAgX3RoaXMucHJlcGFyZUNvbXBvbmVudHMoX3RoaXMuY29tcG9uZXRzKTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhBcHAsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICB2YXIgX3RoaXMyID0gdGhpcztcblxuICAgICAgICAgICAgdmFyIGNvbnRleHQgPSB7fTtcbiAgICAgICAgICAgIHZhciBidG5QYXJhbXMgPSB0aGlzLnByZXBhcmVQYXJhbXNGb3JUb29sYmFyKCk7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICBTdHlsZVJvb3QsXG4gICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IHBhdGg6ICcvbGFwc2VkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChNZW51LCB7IHBhcmFtczogYnRuUGFyYW1zLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJla3ZJZDogRG9jQ29udGV4dC51c2VyRGF0YSA/IERvY0NvbnRleHQudXNlckRhdGEucmVrdmlkIDogMCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KExhc3RlUmVnaXN0ZXIsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kdWxlOiBNT0RVTEUgfSk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9sYXBzJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KExhc3RlUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLCBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9sYXBzLzpkb2NJZCcsIGNvbXBvbmVudDogTGFwc2VEb2t1bWVudCB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC92YW5lbScsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChWYW5lbWF0ZVJlZ2lzdGVyLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSwgbW9kdWxlOiBNT0RVTEUgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvdmFuZW0vOmRvY0lkJywgY29tcG9uZW50OiBWYW5lbURva3VtZW50IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL2xhcHNlX2thYXJ0JyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KExhc3RlVGVlbnVzdFJlZ2lzdGVyLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSwgbW9kdWxlOiBNT0RVTEUgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvbGFwc2Vfa2FhcnQvOmRvY0lkJywgY29tcG9uZW50OiBMYXBzZUthYXJ0RG9rdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvbGFwc2VfdGFhYmVsJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KExhc3RlVGFhYmVsUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLCBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9sYXBzZV90YWFiZWwvOmRvY0lkJywgY29tcG9uZW50OiBMYXBzZVRhYWJlbERva3VtZW50IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL2FydicsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChBcnZlZGVSZWdpc3RlciwgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEsIG1vZHVsZTogTU9EVUxFIH0pO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL2Fydi86ZG9jSWQnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQXJ2ZURvY3VtZW50LCBfZXh0ZW5kcyh7fSwgcHJvcHMsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSB9KSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvam91cm5hbC86ZG9jSWQnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSm91cm5hbERvY3VtZW50LCBfZXh0ZW5kcyh7fSwgcHJvcHMsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSB9KSk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9zbWsnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU21rUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZHVsZTogTU9EVUxFIH0pO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3Ntay86ZG9jSWQnLCBjb21wb25lbnQ6IFNta0RvY3VtZW50IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3NvcmRlcicsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChTb3JkZXJpZGVSZWdpc3Rlciwge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3NvcmRlci86ZG9jSWQnLCBjb21wb25lbnQ6IFNvcmRlckRvY3VtZW50IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL2FzdXR1c2VkLzpkb2NJZCcsIGNvbXBvbmVudDogQXN1dHVzRG9jdW1lbnQsIG1vZHVsZTogTU9EVUxFIH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL2FzdXR1c2VkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KEFzdXR1c1JlZ2lzdGVyLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9ub21lbmNsYXR1cmUnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoTm9tUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLCBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9ub21lbmNsYXR1cmUvOmRvY0lkJywgY29tcG9uZW50OiBOb21Eb2N1bWVudCB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC90dW5udXMvOmRvY0lkJywgY29tcG9uZW50OiBUdW5udXNEb2N1bWVudCB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC90dW5udXMnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVHVubnVzUmVnaXN0ZXIsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2R1bGU6IE1PRFVMRSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSlcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3ByZXBhcmVQYXJhbXNGb3JUb29sYmFyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHByZXBhcmVQYXJhbXNGb3JUb29sYmFyKCkge1xuICAgICAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgICAgICBidG5TdGFydDoge1xuICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBidG5Mb2dpbjoge1xuICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIGJ0bkFjY291bnQ6IHtcbiAgICAgICAgICAgICAgICAgICAgc2hvdzogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICB9O1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdwcmVwYXJlQ29tcG9uZW50cycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBwcmVwYXJlQ29tcG9uZW50cyhjb21wb25lbnRzKSB7XG4gICAgICAgICAgICByZXR1cm4gY29tcG9uZW50c1snTGFwc2VEb2N1bWVudCddID0gZnVuY3Rpb24gKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgdmFyIExhcHNlRG9jdW1lbnQgPSByZXF1aXJlKCcuLy4uL2RvY3MvbGFwcy9kb2N1bWVudC9pbmRleC5qc3gnKTtcbiAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChMYXBzZURvY3VtZW50LCBwcm9wcyk7XG4gICAgICAgICAgICB9O1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIEFwcDtcbn0oUmVhY3QuQ29tcG9uZW50KTtcblxubW9kdWxlLmV4cG9ydHMgPSBBcHA7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9tb2R1bGVzL2xhcHNlZC5qc3hcbi8vIG1vZHVsZSBpZCA9IDQ4XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgRG9jQ29udGV4dCA9IHJlcXVpcmUoJy4uLy4uLy4uL2RvYy1jb250ZXh0Jyk7XG5cbnZhciBQcm9wVHlwZXMgPSByZXF1aXJlKCdwcm9wLXR5cGVzJyk7XG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIF9mZXRjaERhdGEgPSByZXF1aXJlKCcuLy4uLy4uLy4uLy4uL2xpYnMvZmV0Y2hEYXRhJyk7XG52YXIgdG9vbGJhclBhcmFtcyA9IHtcbiAgICBidG5BZGQ6IHtcbiAgICAgICAgc2hvdzogdHJ1ZSxcbiAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgfSxcbiAgICBidG5FZGl0OiB7XG4gICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgIH0sXG4gICAgYnRuRGVsZXRlOiB7XG4gICAgICAgIHNob3c6IGZhbHNlLFxuICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICB9LFxuICAgIGJ0blByaW50OiB7XG4gICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgIH1cbn07XG5cbnZhciBEb2N1bWVudFRlbXBsYXRlID0gcmVxdWlyZSgnLi4vLi4vZG9jdW1lbnRUZW1wbGF0ZS9pbmRleC5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBJbnB1dE51bWJlciA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtbnVtYmVyL2lucHV0LW51bWJlci5qc3gnKSxcbiAgICBTZWxlY3QgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL3NlbGVjdC9zZWxlY3QuanN4JyksXG4gICAgVGV4dEFyZWEgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL3RleHQtYXJlYS90ZXh0LWFyZWEuanN4JyksXG4gICAgRGF0YUdyaWQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2RhdGEtZ3JpZC9kYXRhLWdyaWQuanN4JyksXG4gICAgcmVsYXRlZERvY3VtZW50cyA9IHJlcXVpcmUoJy4uLy4uLy4uL21peGluL3JlbGF0ZWREb2N1bWVudHMuanN4JyksXG4gICAgTW9kYWxQYWdlID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9tb2RhbHBhZ2UvbW9kYWxQYWdlLmpzeCcpLFxuICAgIHN0eWxlcyA9IHJlcXVpcmUoJy4vbGFwcy5zdHlsZXMnKTtcblxudmFyIExJQkRPSyA9ICdMQVBTJyxcbiAgICBMSUJSQVJJRVMgPSBbXTtcblxudmFyIG5vdyA9IG5ldyBEYXRlKCk7XG5cbnZhciBMYXBzID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKExhcHMsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIExhcHMocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIExhcHMpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChMYXBzLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoTGFwcykpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIGxvYWRlZERhdGE6IGZhbHNlLFxuICAgICAgICAgICAgZG9jSWQ6IHByb3BzLmRvY0lkID8gcHJvcHMuZG9jSWQgOiBOdW1iZXIocHJvcHMubWF0Y2gucGFyYW1zLmRvY0lkKSxcbiAgICAgICAgICAgIHZhbmVtSWQ6IG51bGwsXG4gICAgICAgICAgICBtb2R1bGU6ICdsYXBzZWQnXG4gICAgICAgIH07XG5cbiAgICAgICAgX3RoaXMucmVuZGVyZXIgPSBfdGhpcy5yZW5kZXJlci5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlUGFnZUNsaWNrID0gX3RoaXMuaGFuZGxlUGFnZUNsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2sgPSBfdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmZldGNoRGF0YSA9IF90aGlzLmZldGNoRGF0YS5iaW5kKF90aGlzKTtcblxuICAgICAgICBfdGhpcy5kb2NJZCA9IHByb3BzLmRvY0lkID8gcHJvcHMuZG9jSWQgOiBOdW1iZXIocHJvcHMubWF0Y2gucGFyYW1zLmRvY0lkKTtcblxuICAgICAgICBfdGhpcy5wYWdlcyA9IFt7IHBhZ2VOYW1lOiAnTGFwc2Uga2FhcnQnLCBkb2NUeXBlSWQ6ICdMQVBTJyB9LCB7IHBhZ2VOYW1lOiAnVGFhYmVsJywgaGFuZGxlUGFnZUNsaWNrOiBfdGhpcy5oYW5kbGVQYWdlQ2xpY2ssIGRvY1R5cGVJZDogJ0xBUFNFX1RBQUJFTCcgfSwgeyBwYWdlTmFtZTogJ0FydmVkJywgaGFuZGxlUGFnZUNsaWNrOiBfdGhpcy5oYW5kbGVQYWdlQ2xpY2ssIGRvY1R5cGVJZDogJ0FSVicgfSwgeyBwYWdlTmFtZTogJ01ha3Nla29yYWxkdXNlZCcsIGhhbmRsZVBhZ2VDbGljazogX3RoaXMuaGFuZGxlUGFnZUNsaWNrLCBkb2NUeXBlSWQ6ICdTTUsnIH0sIHsgcGFnZU5hbWU6ICdLYXNzYW9yZGVyaWQnLCBoYW5kbGVQYWdlQ2xpY2s6IF90aGlzLmhhbmRsZVBhZ2VDbGljaywgZG9jVHlwZUlkOiAnU09SREVSJyB9XTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhMYXBzLCBbe1xuICAgICAgICBrZXk6ICdjb21wb25lbnREaWRNb3VudCcsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBjb21wb25lbnREaWRNb3VudCgpIHtcbiAgICAgICAgICAgIGlmICh0aGlzLnByb3BzLmhpc3RvcnkgJiYgdGhpcy5wcm9wcy5oaXN0b3J5LmxvY2F0aW9uLnN0YXRlKSB7XG4gICAgICAgICAgICAgICAgdmFyIHZhbmVtSWQgPSB0aGlzLnByb3BzLmhpc3RvcnkubG9jYXRpb24uc3RhdGUudmFuZW1JZDtcbiAgICAgICAgICAgICAgICB2YXIgX21vZHVsZSA9IHRoaXMucHJvcHMuaGlzdG9yeS5sb2NhdGlvbi5zdGF0ZS5tb2R1bGUgPyB0aGlzLnByb3BzLmhpc3RvcnkubG9jYXRpb24uc3RhdGUubW9kdWxlIDogJ2xhcHNlZCc7XG4gICAgICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IHZhbmVtSWQ6IHZhbmVtSWQsIG1vZHVsZTogX21vZHVsZSB9KTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHZhciBpbml0RGF0YSA9IHRoaXMucHJvcHMuaW5pdERhdGEgPyB0aGlzLnByb3BzLmluaXREYXRhIDoge307XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50VGVtcGxhdGUsIHsgZG9jSWQ6IHRoaXMuc3RhdGUuZG9jSWQsXG4gICAgICAgICAgICAgICAgcmVmOiAnZG9jdW1lbnQnLFxuICAgICAgICAgICAgICAgIG1vZHVsZTogdGhpcy5zdGF0ZS5tb2R1bGUsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiAnTEFQUycsXG4gICAgICAgICAgICAgICAgaW5pdERhdGE6IGluaXREYXRhLFxuICAgICAgICAgICAgICAgIGxpYnM6IExJQlJBUklFUyxcbiAgICAgICAgICAgICAgICBwYWdlczogdGhpcy5wYWdlcyxcbiAgICAgICAgICAgICAgICByZW5kZXJlcjogdGhpcy5yZW5kZXJlcixcbiAgICAgICAgICAgICAgICBoYW5kbGVHcmlkQnRuQ2xpY2s6IHRoaXMuaGFuZGxlR3JpZEJ0bkNsaWNrLFxuICAgICAgICAgICAgICAgIGZvY3VzRWxlbWVudDogJ2lucHV0LWlzaWt1a29vZCdcbiAgICAgICAgICAgIH0pO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICrQktC10YDQvdC10YIg0LrQsNGB0YLQvtC80L3Ri9C1INC60L7QvNC/0L7QvdC10L3RgtGLINC00L7QutGD0LzQtdC90YLQsFxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcihzZWxmKSB7XG4gICAgICAgICAgICB2YXIgYnBtID0gc2VsZi5kb2NEYXRhICYmIHNlbGYuZG9jRGF0YS5icG0gPyBzZWxmLmRvY0RhdGEuYnBtIDogW10sXG4gICAgICAgICAgICAgICAgaXNFZGl0TW9kZSA9IHNlbGYuc3RhdGUuZWRpdGVkLFxuICAgICAgICAgICAgICAgIGdyaWRWYW5lbWFkRGF0YSA9IHNlbGYuZG9jRGF0YS52YW5lbWFkLFxuICAgICAgICAgICAgICAgIGdyaWRWYW5lbWFkQ29sdW1ucyA9IHNlbGYuZG9jRGF0YS5ncmlkQ29uZmlnLFxuICAgICAgICAgICAgICAgIGdyaWRUZWVudXN0ZURhdGEgPSBzZWxmLmRvY0RhdGEudGVlbnVzZWQsXG4gICAgICAgICAgICAgICAgZ3JpZFRlZW51c3RlQ29sdW1ucyA9IHNlbGYuZG9jRGF0YS5ncmlkVGVlbnVzdGVDb25maWc7XG5cbiAgICAgICAgICAgIGlmIChzZWxmLmRvY0RhdGEuaWQgPT0gMCkge1xuICAgICAgICAgICAgICAgIC8vbmVldyByZWNvcmRcbiAgICAgICAgICAgICAgICBzZWxmLmRvY0RhdGEudmFuZW1pZCA9IHRoaXMuc3RhdGUudmFuZW1JZDtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgdmFyIGRvYyA9IHRoaXMucmVmc1snZG9jdW1lbnQnXTtcbiAgICAgICAgICAgIHZhciBsaWJzID0gZG9jID8gZG9jLmxpYnMgOiB7fTtcblxuICAgICAgICAgICAgaWYgKCF0aGlzLmRvY0lkICYmIHNlbGYuZG9jRGF0YS5pZCkge1xuICAgICAgICAgICAgICAgIHRoaXMuZG9jSWQgPSBzZWxmLmRvY0RhdGEuaWQ7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2MgfSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyByZWY6ICdpbnB1dC1pc2lrdWtvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpdGxlOiAnSXNpa3Vrb29kOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2lzaWt1a29vZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5pc2lrdWtvb2QgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1heExlbmd0aDogJzExJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnTmltaTonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICduaW1pJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLm5pbWkgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtbmltaScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdWaWl0ZW51bWJlcjonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICd2aWl0ZW51bWJlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS52aWl0ZW51bWJlciB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC12aWl0ZW51bWJlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHJlZjogJ2lucHV0LWphYWsnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpdGxlOiAnSlxceEU0XFx4RTRrOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2phYWsnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuamFhayB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogdHJ1ZVxuICAgICAgICAgICAgICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChUZXh0QXJlYSwgeyB0aXRsZTogJ01cXHhFNHJrdXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd0ZXh0YXJlYS1tdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5tdXVkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2xhYmVsJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVmOiAnbGFiZWwnIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAnVmFuZW1hZCdcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEYXRhR3JpZCwgeyBzb3VyY2U6ICd2YW5lbWFkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIGdyaWREYXRhOiBncmlkVmFuZW1hZERhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICBncmlkQ29sdW1uczogZ3JpZFZhbmVtYWRDb2x1bW5zLFxuICAgICAgICAgICAgICAgICAgICAgICAgc2hvd1Rvb2xCYXI6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgdG9vbGJhclBhcmFtczogdG9vbGJhclBhcmFtcyxcbiAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogc2VsZi5oYW5kbGVHcmlkQnRuQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLmdyaWQuaGVhZGVyVGFibGUsXG4gICAgICAgICAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6ICd2YW5lbScsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd2YW5lbWFkLWRhdGEtZ3JpZCcgfSlcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnbGFiZWwnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWY6ICdsYWJlbCcgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICdUZWVudXNlZCdcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEYXRhR3JpZCwgeyBzb3VyY2U6ICd0ZWVudXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBncmlkRGF0YTogZ3JpZFRlZW51c3RlRGF0YSxcbiAgICAgICAgICAgICAgICAgICAgICAgIGdyaWRDb2x1bW5zOiBncmlkVGVlbnVzdGVDb2x1bW5zLFxuICAgICAgICAgICAgICAgICAgICAgICAgc2hvd1Rvb2xCYXI6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgaGFuZGxlR3JpZEJ0bkNsaWNrOiBzZWxmLmhhbmRsZUdyaWRCdG5DbGljayxcbiAgICAgICAgICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ2xhcHNlX2thYXJ0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMuZ3JpZC5oZWFkZXJUYWJsZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3RlZW51c3RlLWRhdGEtZ3JpZCcgfSlcbiAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdoYW5kbGVQYWdlQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaGFuZGxlUGFnZUNsaWNrKHBhZ2VEb2NUeXBlSWQpIHtcbiAgICAgICAgICAgIC8vINC00LDQvdC90YvQtSDQtNC70Y8g0YTQuNC70YzRgtGA0LBcbiAgICAgICAgICAgIHZhciBpc2lrdWtvb2QgPSB0aGlzLnJlZnNbJ2RvY3VtZW50J10uZG9jRGF0YS5pc2lrdWtvb2Q7XG5cbiAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKHtcbiAgICAgICAgICAgICAgICBwYXRobmFtZTogJy9sYXBzZWQvJyArIHBhZ2VEb2NUeXBlSWQsXG4gICAgICAgICAgICAgICAgc3RhdGU6IHsgaXNpa3Vrb29kOiBpc2lrdWtvb2QsIHR5cGU6ICd0ZXh0JyB9XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8vINC+0LHRgNCw0LHQvtGC0YfQuNC6INGB0L7QsdGL0YLQuNGPINC60LvQuNC6INC90LAg0LPRgNC40LTQtSDRgNC+0LTQuNGC0LXQu9C10LlcblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnaGFuZGxlR3JpZEJ0bkNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZUdyaWRCdG5DbGljayhidG5OYW1lLCBhY3RpdmVSb3csIGlkLCBkb2NUeXBlSWQpIHtcbiAgICAgICAgICAgIHZhciBfdGhpczIgPSB0aGlzO1xuXG4gICAgICAgICAgICBzd2l0Y2ggKGJ0bk5hbWUpIHtcbiAgICAgICAgICAgICAgICBjYXNlIFwiZWRpdFwiOlxuXG4gICAgICAgICAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHBhdGhuYW1lOiAnL2xhcHNlZC8nICsgZG9jVHlwZUlkICsgJy8nICsgaWQsXG4gICAgICAgICAgICAgICAgICAgICAgICBzdGF0ZTogeyBsYXBzSWQ6IHRoaXMuZG9jSWQsIG1vZHVsZTogdGhpcy5zdGF0ZS5tb2R1bGUgfVxuICAgICAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgY2FzZSBcImFkZFwiOlxuICAgICAgICAgICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCh7XG4gICAgICAgICAgICAgICAgICAgICAgICBwYXRobmFtZTogJy9sYXBzZWQvJyArIGRvY1R5cGVJZCArICcvMCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBzdGF0ZTogeyBsYXBzSWQ6IHRoaXMuZG9jSWQsIG1vZHVsZTogdGhpcy5zdGF0ZS5tb2R1bGUgfVxuICAgICAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgY2FzZSBcImRlbGV0ZVwiOlxuICAgICAgICAgICAgICAgICAgICAvL3NlbmQgcG9zdCB0byBkZWxldGUgcm93XG4gICAgICAgICAgICAgICAgICAgIHRoaXMuZmV0Y2hEYXRhKGRvY1R5cGVJZCwgaWQpLnRoZW4oZnVuY3Rpb24gKHJlc3BvbnNlKSB7XG5cbiAgICAgICAgICAgICAgICAgICAgICAgIHZhciBjdXJyZW50ID0gX3RoaXMyLnByb3BzLmxvY2F0aW9uLnBhdGhuYW1lO1xuICAgICAgICAgICAgICAgICAgICAgICAgX3RoaXMyLnByb3BzLmhpc3RvcnkucmVwbGFjZSgnL3JlbG9hZCcpO1xuICAgICAgICAgICAgICAgICAgICAgICAgc2V0VGltZW91dChmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgX3RoaXMyLnByb3BzLmhpc3RvcnkucmVwbGFjZShjdXJyZW50KTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgZGVmYXVsdDpcbiAgICAgICAgICAgICAgICAgICAgY29uc29sZS5sb2coJ1ZpZ2FuZSBjbGljaycpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgLy8g0L7RgtC/0YDQsNCy0LjRgiDQt9Cw0L/RgNC+0YEg0L3QsCDRg9C00LDQu9C10L3QuNC1INGBINC/0LDRgNCw0LzQtdGC0YDQvtC8INGC0LjQvyDQtNC+0LrRg9C80LXQvdGC0LAg0Lgg0LjQtFxuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdmZXRjaERhdGEnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gZmV0Y2hEYXRhKGRvY1R5cGVJZCwgaWQpIHtcblxuICAgICAgICAgICAgdmFyIHVybCA9ICcvbmV3QXBpL2RlbGV0ZSc7XG5cbiAgICAgICAgICAgIHZhciBwYXJhbXMgPSB7XG4gICAgICAgICAgICAgICAgcGFyYW1ldGVyOiBkb2NUeXBlSWQsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiAnbGFwc2VkJyxcbiAgICAgICAgICAgICAgICB1c2VySWQ6IERvY0NvbnRleHQudXNlckRhdGEudXNlcklkLFxuICAgICAgICAgICAgICAgIHV1aWQ6IERvY0NvbnRleHQudXNlckRhdGEudXVpZCxcbiAgICAgICAgICAgICAgICBkb2NJZDogaWRcbiAgICAgICAgICAgIH07XG5cbiAgICAgICAgICAgIHJldHVybiBfZmV0Y2hEYXRhWydmZXRjaERhdGFQb3N0J10odXJsLCBwYXJhbXMpO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIExhcHM7XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5MYXBzLnByb3BUeXBlcyA9IHtcbiAgICBkb2NJZDogUHJvcFR5cGVzLm51bWJlcixcbiAgICBpbml0RGF0YTogUHJvcFR5cGVzLm9iamVjdCxcbiAgICB1c2VyRGF0YTogUHJvcFR5cGVzLm9iamVjdFxufTtcblxuTGFwcy5kZWZhdWx0UHJvcHMgPSB7XG4gICAgcGFyYW1zOiB7IGRvY0lkOiAwIH0sXG4gICAgaW5pdERhdGE6IHt9LFxuICAgIHVzZXJEYXRhOiB7fVxufTtcblxubW9kdWxlLmV4cG9ydHMgPSBMYXBzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzL2RvY3VtZW50L2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMjE5XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgZG9jUm93OiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ3JvdydcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBibHVlJ1xyXG4gICAgICAgICovXG4gICAgfSxcbiAgICBkb2NDb2x1bW46IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJyxcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCB5ZWxsb3cnLFxyXG4gICAgICAgICovXG4gICAgICAgIHdpZHRoOiAnNTAlJ1xuICAgIH0sXG4gICAgZG9jOiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ2NvbHVtbidcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBicm93bidcclxuICAgICAgICAqL1xuICAgIH0sXG5cbiAgICBncmlkOiB7XG4gICAgICAgIG1haW5UYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuICAgICAgICBoZWFkZXJUYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuXG4gICAgICAgIGdyaWRDb250YWluZXI6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfVxuXG4gICAgfSxcblxuICAgIGdyaWRSb3c6IHtcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBibGFjaycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgYmFja2dyb3VuZENvbG9yOiAnd2hpdGUnLFxuICAgICAgICBwb3NpdGlvbjogJ3JlbGF0aXZlJyxcbiAgICAgICAgbWFyZ2luOiAnMTAlIDMwJSAxMCUgMzAlJyxcbiAgICAgICAgd2lkdGg6ICdhdXRvJyxcbiAgICAgICAgb3BhY2l0eTogJzEnLFxuICAgICAgICB0b3A6ICcxMDBweCdcbiAgICB9XG5cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHMvZG9jdW1lbnQvbGFwcy5zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDIyMFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcbnZhciBEb2N1bWVudFJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2N1bWVudHMvZG9jdW1lbnRzLmpzeCcpO1xudmFyIHN0eWxlcyA9IHJlcXVpcmUoJy4vbGFwcy1yZWdpc3Rlci1zdHlsZXMnKTtcbnZhciBET0NfVFlQRV9JRCA9ICdMQVBTJztcblxuLyoqXHJcbiAqINCa0LvQsNGB0YEg0YDQtdCw0LvQuNC30YPQtdGCINC00L7QutGD0LzQtdC90YIg0YHQv9GA0LDQstC+0YfQvdC40LrQsCDQv9GA0LjQt9C90LDQutC+0LIuXHJcbiAqL1xuXG52YXIgRG9jdW1lbnRzID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKERvY3VtZW50cywgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gRG9jdW1lbnRzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBEb2N1bWVudHMpO1xuXG4gICAgICAgIHJldHVybiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoRG9jdW1lbnRzLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoRG9jdW1lbnRzKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2N1bWVudHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFJlZ2lzdGVyLCB7IGluaXREYXRhOiB0aGlzLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSA/IHRoaXMucHJvcHMuaGlzdG9yeSA6IG51bGwsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnByb3BzLm1vZHVsZSxcbiAgICAgICAgICAgICAgICByZWY6ICdyZWdpc3RlcicsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiBET0NfVFlQRV9JRCxcbiAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLFxuICAgICAgICAgICAgICAgIHJlbmRlcjogdGhpcy5yZW5kZXJlciB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICdMYXN0ZSByZWdpc3RlciBzcGVjaWFsIHJlbmRlcidcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gRG9jdW1lbnRzO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxubW9kdWxlLmV4cG9ydHMgPSBEb2N1bWVudHM7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHMvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyMjFcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBncmlkOiB7XG4gICAgICAgIG1haW5UYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuICAgICAgICBoZWFkZXJUYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuXG4gICAgICAgIGdyaWRDb250YWluZXI6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfVxuXG4gICAgfVxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvbGFwcy9sYXBzLXJlZ2lzdGVyLXN0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjI3XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIERvY3VtZW50UmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3VtZW50cy9kb2N1bWVudHMuanN4Jyk7XG52YXIgc3R5bGVzID0gcmVxdWlyZSgnLi9zdHlsZXMnKTtcbnZhciBET0NfVFlQRV9JRCA9ICdMQVBTRV9LQUFSVCc7XG5cbi8qKlxyXG4gKiDQmtC70LDRgdGBINGA0LXQsNC70LjQt9GD0LXRgiDQtNC+0LrRg9C80LXQvdGCINGB0L/RgNCw0LLQvtGH0L3QuNC60LAg0L/RgNC40LfQvdCw0LrQvtCyLlxyXG4gKi9cblxudmFyIERvY3VtZW50cyA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhEb2N1bWVudHMsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIERvY3VtZW50cyhwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgRG9jdW1lbnRzKTtcblxuICAgICAgICByZXR1cm4gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKERvY3VtZW50cy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKERvY3VtZW50cykpLmNhbGwodGhpcywgcHJvcHMpKTtcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoRG9jdW1lbnRzLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRSZWdpc3RlciwgeyBpbml0RGF0YTogdGhpcy5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICB1c2VyRGF0YTogdGhpcy5wcm9wcy51c2VyRGF0YSxcbiAgICAgICAgICAgICAgICBoaXN0b3J5OiB0aGlzLnByb3BzLmhpc3RvcnkgPyB0aGlzLnByb3BzLmhpc3RvcnkgOiBudWxsLFxuICAgICAgICAgICAgICAgIG1vZHVsZTogdGhpcy5wcm9wcy5tb2R1bGUsXG4gICAgICAgICAgICAgICAgcmVmOiAncmVnaXN0ZXInLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogRE9DX1RZUEVfSUQsXG4gICAgICAgICAgICAgICAgc3R5bGU6IHN0eWxlcyxcbiAgICAgICAgICAgICAgICByZW5kZXI6IHRoaXMucmVuZGVyZXIgfSk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcmVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcmVyKCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICAnTGFwc2UgdGVlbnVzdGUgcmVnaXN0ZXIgc3BlY2lhbCByZW5kZXInXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIERvY3VtZW50cztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gRG9jdW1lbnRzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzZV9rYWFydC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDIyOFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9XG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzZV9rYWFydC9zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDIyOVxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFByb3BUeXBlcyA9IHJlcXVpcmUoJ3Byb3AtdHlwZXMnKTtcbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG5cbnZhciBEb2N1bWVudFRlbXBsYXRlID0gcmVxdWlyZSgnLi4vLi4vZG9jdW1lbnRUZW1wbGF0ZS9pbmRleC5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBJbnB1dE51bWJlciA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtbnVtYmVyL2lucHV0LW51bWJlci5qc3gnKSxcbiAgICBCdXR0b25FZGl0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9idXR0b24tcmVnaXN0ZXIvYnV0dG9uLXJlZ2lzdGVyLWVkaXQvYnV0dG9uLXJlZ2lzdGVyLWVkaXQuanN4JyksXG4gICAgSW5wdXREYXRlID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC1kYXRlL2lucHV0LWRhdGUuanN4JyksXG4gICAgU2VsZWN0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3Qvc2VsZWN0LmpzeCcpLFxuICAgIENoZWNrQm94ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC1jaGVja2JveC9pbnB1dC1jaGVja2JveC5qc3gnKSxcbiAgICBTZWxlY3REYXRhID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3QtZGF0YS9zZWxlY3QtZGF0YS5qc3gnKSxcbiAgICBUZXh0QXJlYSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvdGV4dC1hcmVhL3RleHQtYXJlYS5qc3gnKSxcbiAgICBEYXRhR3JpZCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvZGF0YS1ncmlkL2RhdGEtZ3JpZC5qc3gnKSxcbiAgICBNb2RhbFBhZ2UgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL21vZGFscGFnZS9tb2RhbFBhZ2UuanN4JyksXG4gICAgc3R5bGVzID0gcmVxdWlyZSgnLi9zdHlsZXMnKTtcblxudmFyIExJQkRPSyA9ICdMQVBTRV9LQUFSVCcsXG4gICAgTElCUkFSSUVTID0gW3sgaWQ6ICd0dW5udXMnLCBmaWx0ZXI6ICcnIH0sIHtcbiAgICBpZDogJ25vbWVuY2xhdHVyZScsXG4gICAgZmlsdGVyOiAnd2hlcmUgZG9rID0gXFwnQVJWXFwnJ1xufV07XG5cbnZhciBub3cgPSBuZXcgRGF0ZSgpO1xuXG52YXIgTGFwcyA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhMYXBzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBMYXBzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBMYXBzKTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoTGFwcy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKExhcHMpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMuc3RhdGUgPSB7XG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCksXG4gICAgICAgICAgICBtb2R1bGU6ICdsYXBzZWQnXG4gICAgICAgIH07XG4gICAgICAgIC8vICAgICAgICBsYXBzSWQ6IHByb3BzLmxhcHNJZCA/IHByb3BzLmxhcHNJZCA6IHByb3BzLm1hdGNoLnBhcmFtcy5sYXBzSWQgPyBOdW1iZXIocHJvcHMubWF0Y2gucGFyYW1zLmxhcHNJZCkgOiAwXG5cbiAgICAgICAgX3RoaXMucmVuZGVyZXIgPSBfdGhpcy5yZW5kZXJlci5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlUGFnZUNsaWNrID0gX3RoaXMuaGFuZGxlUGFnZUNsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2sgPSBfdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmJ0bkVkaXROb21DbGljayA9IF90aGlzLmJ0bkVkaXROb21DbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuYnRuRWRpdExhcHNDbGljayA9IF90aGlzLmJ0bkVkaXRMYXBzQ2xpY2suYmluZChfdGhpcyk7XG5cbiAgICAgICAgX3RoaXMucGFnZXMgPSBbeyBwYWdlTmFtZTogJ1RlZW51cycsIGRvY1R5cGVJZDogJ0xBUFNFX0tBQVJUJyB9XTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhMYXBzLCBbe1xuICAgICAgICBrZXk6ICdjb21wb25lbnREaWRNb3VudCcsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBjb21wb25lbnREaWRNb3VudCgpIHtcbiAgICAgICAgICAgIHZhciBsYXBzSWQgPSB2b2lkIDA7XG4gICAgICAgICAgICBpZiAodGhpcy5wcm9wcy5oaXN0b3J5ICYmIHRoaXMucHJvcHMuaGlzdG9yeS5sb2NhdGlvbi5zdGF0ZSkge1xuICAgICAgICAgICAgICAgIGxhcHNJZCA9IHRoaXMucHJvcHMuaGlzdG9yeS5sb2NhdGlvbi5zdGF0ZS5sYXBzSWQ7XG4gICAgICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IGxhcHNJZDogbGFwc0lkIH0pO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgdmFyIGluaXREYXRhID0gdGhpcy5wcm9wcy5pbml0RGF0YSA/IHRoaXMucHJvcHMuaW5pdERhdGEgOiB7fTtcblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRUZW1wbGF0ZSwgeyBkb2NJZDogdGhpcy5zdGF0ZS5kb2NJZCxcbiAgICAgICAgICAgICAgICByZWY6ICdkb2N1bWVudCcsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnN0YXRlLm1vZHVsZSxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6ICdMQVBTRV9LQUFSVCcsXG4gICAgICAgICAgICAgICAgdXNlckRhdGE6IHRoaXMucHJvcHMudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgaW5pdERhdGE6IGluaXREYXRhLFxuICAgICAgICAgICAgICAgIGxpYnM6IExJQlJBUklFUyxcbiAgICAgICAgICAgICAgICBwYWdlczogdGhpcy5wYWdlcyxcbiAgICAgICAgICAgICAgICByZW5kZXJlcjogdGhpcy5yZW5kZXJlcixcbiAgICAgICAgICAgICAgICBoYW5kbGVHcmlkQnRuQ2xpY2s6IHRoaXMuaGFuZGxlR3JpZEJ0bkNsaWNrLFxuICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICBmb2N1c0VsZW1lbnQ6ICdpbnB1dC1rb29kJ1xuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKtCS0LXRgNC90LXRgiDQutCw0YHRgtC+0LzQvdGL0LUg0LrQvtC80L/QvtC90LXQvdGC0Ysg0LTQvtC60YPQvNC10L3RgtCwXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcmVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcmVyKHNlbGYpIHtcbiAgICAgICAgICAgIHZhciBicG0gPSBzZWxmLmRvY0RhdGEgJiYgc2VsZi5kb2NEYXRhLmJwbSA/IHNlbGYuZG9jRGF0YS5icG0gOiBbXSxcbiAgICAgICAgICAgICAgICBpc0VkaXRNb2RlID0gc2VsZi5zdGF0ZS5lZGl0ZWQ7XG5cbiAgICAgICAgICAgIGlmICgoc2VsZi5kb2NEYXRhLmlkID09IDAgfHwgIXNlbGYuZG9jRGF0YS5wYXJlbnRpZCkgJiYgdGhpcy5zdGF0ZS5sYXBzSWQpIHtcbiAgICAgICAgICAgICAgICAvL25ldyByZWNvcmRcbiAgICAgICAgICAgICAgICBzZWxmLmRvY0RhdGEucGFyZW50aWQgPSB0aGlzLnN0YXRlLmxhcHNJZDtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgdmFyIGJ1dHRvbkVkaXROb20gPSBzdHlsZXMuYnRuRWRpdE5vbTtcblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvYyB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0RGF0YSwgeyB0aXRsZTogJ0xhcHNlIG5pbWk6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAncGFyZW50aWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHVzZXJEYXRhOiBzZWxmLnVzZXJEYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYk5hbWU6ICdsYXBzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzcWxGaWVsZHM6IFsnbmltaScsICdpc2lrdWtvb2QnXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBbXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnBhcmVudGlkIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVmYXVsdFZhbHVlOiBzZWxmLmRvY0RhdGEubGFwc2VfbmltaSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBib3VuZFRvR3JpZDogJ25pbWknLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJvdW5kVG9EYXRhOiAnbGFwc2VfbmltaScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LXBhcmVudGlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBidG5EZWxldGU6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEJ1dHRvbkVkaXQsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdidG5FZGl0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrOiB0aGlzLmJ0bkVkaXRMYXBzQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc2hvdzogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGU6IGJ1dHRvbkVkaXROb20sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdCwgeyB0aXRsZTogJ0tvb2Q6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbm9taWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYnM6ICdub21lbmNsYXR1cmUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHNlbGYubGlic1snbm9tZW5jbGF0dXJlJ10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5ub21pZCB8fCAwLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlZmF1bHRWYWx1ZTogc2VsZi5kb2NEYXRhLmtvb2QsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LW5vbWlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xsSWQ6ICdpZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYnRuRGVsZXRlOiBpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEJ1dHRvbkVkaXQsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdidG5FZGl0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrOiB0aGlzLmJ0bkVkaXROb21DbGljayxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzaG93OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGU6IGJ1dHRvbkVkaXROb21cbiAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgcmVmOiAnaW5wdXQtaGluZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdIaW5kOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2hpbmQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIoc2VsZi5kb2NEYXRhLmhpbmQpIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdcXHhEQ2tzdXM6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAneWtzdXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEueWtzdXMgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQteWtzdXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnVHVubnVzOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3R1bm51cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbGliczogJ3R1bm51cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogc2VsZi5saWJzWyd0dW5udXMnXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnR1bm51cyB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHNlbGYuZG9jRGF0YS50dW5udXMgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LXR1bm51cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sbElkOiAna29vZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYnRuRGVsZXRlOiBpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZVxuICAgICAgICAgICAgICAgICAgICAgICAgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KENoZWNrQm94LCB7IHRpdGxlOiAnS2FzIGFydmVzdGEgZXJhbGRpPycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2thc19lcmFsZGknLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBCb29sZWFuKHNlbGYuZG9jRGF0YS5rYXNfZXJhbGRpKSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdjaGVja2JveF9rYXNfZXJhbGRpJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGVcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChDaGVja0JveCwgeyB0aXRsZTogJ0thcyBldHRlbWFrcz8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrYXNfZXR0ZW1ha3MnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBCb29sZWFuKHNlbGYuZG9jRGF0YS5rYXNfZXR0ZW1ha3MpLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2NoZWNrYm94X2thc19ldHRlbWFrcycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7IHJlZjogJ2lucHV0LXNvb2R1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdTb29kdXN0dXM6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnc29vZHVzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHNlbGYuZG9jRGF0YS5zb29kdXMpIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dERhdGUsIHsgdGl0bGU6ICdLZWh0aWIgYWxhdGVzOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3Nvb2R1c2VfYWxnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnNvb2R1c2VfYWxnIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXNvb2R1c19hbGcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXREYXRlLCB7IHRpdGxlOiAnS2VodGliIGt1bmk6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnc29vZHVzZV9sb3BwJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnNvb2R1c2VfbG9wcCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1zb29kdXNfbG9wcCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdNXFx4RTRya3VzZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ211dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubXV1ZCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVBhZ2VDbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVQYWdlQ2xpY2socGFnZURvY1R5cGVJZCkge1xuICAgICAgICAgICAgLy8gICAgICAgIGRvY3VtZW50LmxvY2F0aW9uLmhyZWYgPSBgL2xhcHNlZC8ke3BhZ2VEb2NUeXBlSWR9L2A7Ly9AdG9kbyDQntCx0L3QvtCy0LjRgtGMXG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC8nICsgcGFnZURvY1R5cGVJZCk7XG4gICAgICAgIH1cblxuICAgICAgICAvLyDQvtCx0YDQsNCx0L7RgtGH0LjQuiDRgdC+0LHRi9GC0LjRjyDQutC70LjQuiDQvdCwINCz0YDQuNC00LUg0YDQvtC00LjRgtC10LvQtdC5XG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZUdyaWRCdG5DbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVHcmlkQnRuQ2xpY2soYnRuTmFtZSwgYWN0aXZlUm93LCBpZCwgZG9jVHlwZUlkKSB7XG4gICAgICAgICAgICBzd2l0Y2ggKGJ0bk5hbWUpIHtcbiAgICAgICAgICAgICAgICBjYXNlIFwiZWRpdFwiOlxuICAgICAgICAgICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC8nICsgZG9jVHlwZUlkICsgJy8nICsgaWQpO1xuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICBjYXNlIFwiYWRkXCI6XG4gICAgICAgICAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKCcvbGFwc2VkLycgKyBkb2NUeXBlSWQgKyAnLzAvJyArIHRoaXMuc3RhdGUuZG9jSWQpO1xuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICBjYXNlIFwiZGVsZXRlXCI6XG4gICAgICAgICAgICAgICAgICAgIGNvbnNvbGUubG9nKCdidG5EZWxldGUgY2xpY2tlZCcpO1xuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICBkZWZhdWx0OlxuICAgICAgICAgICAgICAgICAgICBjb25zb2xlLmxvZygnVmlnYW5lIGNsaWNrJyk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICAvL9C+0LHRgNCw0LHQvtGC0YfQuNC6INGB0L7QsdGL0YLQuNGPINC/0L4g0LrQu9C40LrRgyDQutC90L7Qv9C60Lgg0KDQtdC00LDQutGC0LjRgNC+0LLQsNC90LjQtSDRgdC90L7QvNC10L3QutC70LDRgtGD0YDRi1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdidG5FZGl0Tm9tQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gYnRuRWRpdE5vbUNsaWNrKCkge1xuICAgICAgICAgICAgdmFyIGRvY05vbUlkID0gdGhpcy5yZWZzWydkb2N1bWVudCddLmRvY0RhdGEubm9taWQ7XG5cbiAgICAgICAgICAgIC8vINC+0YHRg9GJ0LXRgdGC0LLQuNGCINC/0LXRgNC10YXQvtC0INC90LAg0LrQsNGA0YLQvtGH0LrRgyDQutC+0L3RgtGALdCw0LPQtdC90YLQsFxuICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goJy9sYXBzZWQvbm9tZW5jbGF0dXJlLycgKyBkb2NOb21JZCk7XG4gICAgICAgIH1cblxuICAgICAgICAvL9C+0LHRgNCw0LHQvtGC0YfQuNC6INGB0L7QsdGL0YLQuNGPINC/0L4g0LrQu9C40LrRgyDQutC90L7Qv9C60Lgg0KDQtdC00LDQutGC0LjRgNC+0LLQsNC90LjQtSDRgNC10LHQtdC90LrQsFxuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdidG5FZGl0TGFwc0NsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGJ0bkVkaXRMYXBzQ2xpY2soKSB7XG4gICAgICAgICAgICB2YXIgZG9jTGFwc0lkID0gdGhpcy5yZWZzWydkb2N1bWVudCddLmRvY0RhdGEucGFyZW50aWQ7XG5cbiAgICAgICAgICAgIC8vINC+0YHRg9GJ0LXRgdGC0LLQuNGCINC/0LXRgNC10YXQvtC0INC90LAg0LrQsNGA0YLQvtGH0LrRgyDQutC+0L3RgtGALdCw0LPQtdC90YLQsFxuICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goe1xuICAgICAgICAgICAgICAgIHBhdGhuYW1lOiAnL2xhcHNlZC9sYXBzLycgKyBkb2NMYXBzSWQsXG4gICAgICAgICAgICAgICAgc3RhdGU6IHsgdGVlbnVzSWQ6IHRoaXMuc3RhdGUuZG9jSWQsIG1vZHVsZTogdGhpcy5zdGF0ZS5tb2R1bGUgfVxuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gTGFwcztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbkxhcHMucHJvcFR5cGVzID0ge1xuICAgIGRvY0lkOiBQcm9wVHlwZXMubnVtYmVyLFxuICAgIGluaXREYXRhOiBQcm9wVHlwZXMub2JqZWN0LFxuICAgIHVzZXJEYXRhOiBQcm9wVHlwZXMub2JqZWN0XG59O1xuXG5MYXBzLmRlZmF1bHRQcm9wcyA9IHtcbiAgICBwYXJhbXM6IHsgZG9jSWQ6IDAgfSxcbiAgICBpbml0RGF0YToge30sXG4gICAgdXNlckRhdGE6IHt9XG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IExhcHM7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHNlX2thYXJ0L2RvY3VtZW50L2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMjMwXG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xudmFyIHJhZGl1bSA9IHJlcXVpcmUoJ3JhZGl1bScpO1xuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpLFxuICAgIHN0eWxlcyA9IHJlcXVpcmUoJy4vc3R5bGVzJyk7XG5cbnZhciBJbnB1dCA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhJbnB1dCwgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gSW5wdXQocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIElucHV0KTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoSW5wdXQuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihJbnB1dCkpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIHZhbHVlOiBCb29sZWFuKHByb3BzLnZhbHVlKSxcbiAgICAgICAgICAgIHJlYWRPbmx5OiBwcm9wcy5yZWFkT25seSxcbiAgICAgICAgICAgIGRpc2FibGVkOiBwcm9wcy5kaXNhYmxlZFxuICAgICAgICB9O1xuICAgICAgICBfdGhpcy5vbkNoYW5nZSA9IF90aGlzLm9uQ2hhbmdlLmJpbmQoX3RoaXMpO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgLy8gd2lsbCB1cGRhdGUgc3RhdGUgaWYgcHJvcHMgY2hhbmdlZFxuXG5cbiAgICBfY3JlYXRlQ2xhc3MoSW5wdXQsIFt7XG4gICAgICAgIGtleTogJ2NvbXBvbmVudERpZE1vdW50JyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGNvbXBvbmVudERpZE1vdW50KCkge1xuICAgICAgICAgICAgdGhpcy5yZWZzWydjaGVja2JveCddLmNoZWNrZWQgPSB0aGlzLnN0YXRlLnZhbHVlO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdvbkNoYW5nZScsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBvbkNoYW5nZShlKSB7XG4gICAgICAgICAgICB2YXIgdmFsdWUgPSBlLnRhcmdldC5jaGVja2VkO1xuXG4gICAgICAgICAgICB0aGlzLnNldFN0YXRlKHsgdmFsdWU6IHZhbHVlIH0pO1xuXG4gICAgICAgICAgICBpZiAoIXRoaXMuc3RhdGUucmVhZE9ubHkgJiYgdGhpcy5wcm9wcy5vbkNoYW5nZSkge1xuICAgICAgICAgICAgICAgIHRoaXMucHJvcHMub25DaGFuZ2UodGhpcy5wcm9wcy5uYW1lLCB2YWx1ZSk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICB2YXIgaW5wdXRTdHlsZSA9IE9iamVjdC5hc3NpZ24oe30sIHN0eWxlcy5pbnB1dCwgdGhpcy5wcm9wcy53aWR0aCA/IHsgd2lkdGg6IHRoaXMucHJvcHMud2lkdGggfSA6IHt9LCB0aGlzLnN0YXRlLnJlYWRPbmx5ID8gc3R5bGVzLnJlYWRPbmx5IDoge30pO1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMud3JhcHBlciB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdsYWJlbCcsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5sYWJlbCwgaHRtbEZvcjogdGhpcy5wcm9wcy5uYW1lLCByZWY6ICdsYWJlbCcgfSxcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy50aXRsZVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudCgnaW5wdXQnLCB7IHR5cGU6ICdjaGVja2JveCcsXG4gICAgICAgICAgICAgICAgICAgIGlkOiB0aGlzLnByb3BzLm5hbWUsXG4gICAgICAgICAgICAgICAgICAgIHJlZjogJ2NoZWNrYm94JyxcbiAgICAgICAgICAgICAgICAgICAgc3R5bGU6IGlucHV0U3R5bGUsXG4gICAgICAgICAgICAgICAgICAgIG5hbWU6IHRoaXMucHJvcHMubmFtZSxcbiAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHRoaXMuc3RhdGUudmFsdWUsXG4gICAgICAgICAgICAgICAgICAgIGNoZWNrZWQ6IHRoaXMuc3RhdGUudmFsdWUsXG4gICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiB0aGlzLnN0YXRlLnJlYWRPbmx5LFxuICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5vbkNoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IHRoaXMuc3RhdGUucmVhZE9ubHlcbiAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINGD0YHRgtCw0L3QvtCy0LjRgiDRhNC+0LrRg9GBINC90LAg0Y3Qu9C10LzQtdC90YLRi1xyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdmb2N1cycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBmb2N1cygpIHtcbiAgICAgICAgICAgIHRoaXMucmVmc1snY2hlY2tib3gnXS5mb2N1cygpO1xuICAgICAgICB9XG4gICAgfV0sIFt7XG4gICAgICAgIGtleTogJ2dldERlcml2ZWRTdGF0ZUZyb21Qcm9wcycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBnZXREZXJpdmVkU3RhdGVGcm9tUHJvcHMobmV4dFByb3BzLCBwcmV2U3RhdGUpIHtcbiAgICAgICAgICAgIGlmIChuZXh0UHJvcHMudmFsdWUgIT09IHByZXZTdGF0ZS52YWx1ZSB8fCBuZXh0UHJvcHMucmVhZE9ubHkgIT09IHByZXZTdGF0ZS5yZWFkT25seSkge1xuICAgICAgICAgICAgICAgIHJldHVybiB7IHZhbHVlOiBuZXh0UHJvcHMudmFsdWUsIHJlYWRPbmx5OiBuZXh0UHJvcHMucmVhZE9ubHkgfTtcbiAgICAgICAgICAgIH0gZWxzZSByZXR1cm4gbnVsbDtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBJbnB1dDtcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbklucHV0LnByb3BUeXBlcyA9IHtcbiAgICBuYW1lOiBQcm9wVHlwZXMuc3RyaW5nLmlzUmVxdWlyZWQsXG4gICAgdmFsdWU6IFByb3BUeXBlcy5ib29sLFxuICAgIHJlYWRPbmx5OiBQcm9wVHlwZXMuYm9vbCxcbiAgICBkaXNhYmxlZDogUHJvcFR5cGVzLmJvb2wsXG4gICAgdGl0bGU6IFByb3BUeXBlcy5zdHJpbmdcbn07XG5cbklucHV0LmRlZmF1bHRQcm9wcyA9IHtcbiAgICByZWFkT25seTogZmFsc2UsXG4gICAgZGlzYWJsZWQ6IGZhbHNlLFxuICAgIHZhbHVlOiBmYWxzZSxcbiAgICB0aXRsZTogJydcbn07XG5cbm1vZHVsZS5leHBvcnRzID0gcmFkaXVtKElucHV0KTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2NvbXBvbmVudHMvaW5wdXQtY2hlY2tib3gvaW5wdXQtY2hlY2tib3guanN4XG4vLyBtb2R1bGUgaWQgPSAyMzFcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBpbnB1dDoge1xuICAgICAgICAnOmZvY3VzJzoge1xuICAgICAgICAgICAgYmFja2dyb3VuZENvbG9yOiAnbGlnaHRwaW5rJ1xuICAgICAgICB9XG4gICAgfSxcbiAgICByZWFkT25seToge1xuICAgICAgICBiYWNrZ3JvdW5kQ29sb3I6ICcjRjNFRkVGJ1xuICAgIH0sXG4gICAgd3JhcHBlcjoge1xuICAgICAgICBtYXJnaW46ICc1cHgnLFxuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIHdpZHRoOiAnOTUlJ1xuICAgIH0sXG4gICAgbGFiZWw6IHtcbiAgICAgICAgd2lkdGg6ICczMCUnLFxuICAgICAgICBtYXJnaW46ICc1cHgnXG4gICAgfVxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2NvbXBvbmVudHMvaW5wdXQtY2hlY2tib3gvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyMzJcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBkb2NSb3c6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAncm93J1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsdWUnXHJcbiAgICAgICAgKi9cbiAgICB9LFxuICAgIGRvY0NvbHVtbjoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nLFxuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIHllbGxvdycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgd2lkdGg6ICc1MCUnXG4gICAgfSxcbiAgICBkb2M6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJ1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJyb3duJ1xyXG4gICAgICAgICovXG4gICAgfSxcblxuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9LFxuXG4gICAgZ3JpZFJvdzoge1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsYWNrJyxcclxuICAgICAgICAqL1xuICAgICAgICBiYWNrZ3JvdW5kQ29sb3I6ICd3aGl0ZScsXG4gICAgICAgIHBvc2l0aW9uOiAncmVsYXRpdmUnLFxuICAgICAgICBtYXJnaW46ICcxMCUgMzAlIDEwJSAzMCUnLFxuICAgICAgICB3aWR0aDogJ2F1dG8nLFxuICAgICAgICBvcGFjaXR5OiAnMScsXG4gICAgICAgIHRvcDogJzEwMHB4J1xuICAgIH0sXG5cbiAgICBidG5FZGl0Tm9tOiB7XG4gICAgICAgIHdpZHRoOiAnbWluLWNvbnRlbnQnXG4gICAgfSxcblxuICAgIHNlbGVjdE5vbToge1xuICAgICAgICBtYXJnaW5MZWZ0OiAnMTBweCdcbiAgICB9XG5cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHNlX2thYXJ0L2RvY3VtZW50L3N0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjM2XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIERvY3VtZW50UmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3VtZW50cy9kb2N1bWVudHMuanN4Jyk7XG52YXIgc3R5bGVzID0gcmVxdWlyZSgnLi9zdHlsZXMnKTtcbnZhciBET0NfVFlQRV9JRCA9ICdMQVBTRV9UQUFCRUwnO1xuXG4vKipcclxuICog0JrQu9Cw0YHRgSDRgNC10LDQu9C40LfRg9C10YIg0LTQvtC60YPQvNC10L3RgiDRgdC/0YDQsNCy0L7Rh9C90LjQutCwINC/0YDQuNC30L3QsNC60L7Qsi5cclxuICovXG5cbnZhciBEb2N1bWVudHMgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoRG9jdW1lbnRzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBEb2N1bWVudHMocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIERvY3VtZW50cyk7XG5cbiAgICAgICAgcmV0dXJuIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChEb2N1bWVudHMuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihEb2N1bWVudHMpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKERvY3VtZW50cywgW3tcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50UmVnaXN0ZXIsIHsgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICBtb2R1bGU6IHRoaXMucHJvcHMubW9kdWxlLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6IERPQ19UWVBFX0lELFxuICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMsXG4gICAgICAgICAgICAgICAgcmVuZGVyOiB0aGlzLnJlbmRlcmVyIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgJ0xhcHNlIHRhYWJlbCByZWdpc3RlciBzcGVjaWFsIHJlbmRlcidcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gRG9jdW1lbnRzO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxubW9kdWxlLmV4cG9ydHMgPSBEb2N1bWVudHM7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHNlX3RhYWJlbC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDIzN1xuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9XG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzZV90YWFiZWwvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyMzhcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBQcm9wVHlwZXMgPSByZXF1aXJlKCdwcm9wLXR5cGVzJyk7XG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xuXG52YXIgRG9jdW1lbnRUZW1wbGF0ZSA9IHJlcXVpcmUoJy4uLy4uL2RvY3VtZW50VGVtcGxhdGUvaW5kZXguanN4JyksXG4gICAgSW5wdXRUZXh0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC10ZXh0L2lucHV0LXRleHQuanN4JyksXG4gICAgSW5wdXROdW1iZXIgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LW51bWJlci9pbnB1dC1udW1iZXIuanN4JyksXG4gICAgQnV0dG9uRWRpdCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi1yZWdpc3Rlci1lZGl0L2J1dHRvbi1yZWdpc3Rlci1lZGl0LmpzeCcpLFxuICAgIElucHV0RGF0ZSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtZGF0ZS9pbnB1dC1kYXRlLmpzeCcpLFxuICAgIFNlbGVjdCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvc2VsZWN0L3NlbGVjdC5qc3gnKSxcbiAgICBTZWxlY3REYXRhID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3QtZGF0YS9zZWxlY3QtZGF0YS5qc3gnKSxcbiAgICBUZXh0QXJlYSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvdGV4dC1hcmVhL3RleHQtYXJlYS5qc3gnKSxcbiAgICBEYXRhR3JpZCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvZGF0YS1ncmlkL2RhdGEtZ3JpZC5qc3gnKSxcbiAgICBNb2RhbFBhZ2UgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL21vZGFscGFnZS9tb2RhbFBhZ2UuanN4JyksXG4gICAgc3R5bGVzID0gcmVxdWlyZSgnLi9zdHlsZXMnKTtcblxudmFyIExJQkRPSyA9ICdMQVBTRV9UQUFCRUwnLFxuICAgIExJQlJBUklFUyA9IFt7IGlkOiAnbGFwc2Vfa2FhcnQnLCBmaWx0ZXI6ICcnIH1dO1xuXG52YXIgbm93ID0gbmV3IERhdGUoKTtcblxudmFyIExhcHMgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoTGFwcywgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gTGFwcyhwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgTGFwcyk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKExhcHMuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihMYXBzKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgbW9kdWxlOiAnbGFwc2VkJyxcbiAgICAgICAgICAgIGxvYWRlZERhdGE6IGZhbHNlLFxuICAgICAgICAgICAgZG9jSWQ6IHByb3BzLmRvY0lkID8gcHJvcHMuZG9jSWQgOiBOdW1iZXIocHJvcHMubWF0Y2gucGFyYW1zLmRvY0lkKSxcbiAgICAgICAgICAgIGxhcHNJZDogcHJvcHMubGFwc0lkID8gcHJvcHMubGFwc0lkIDogcHJvcHMubWF0Y2gucGFyYW1zLnBhcmFtSWQgPyBOdW1iZXIocHJvcHMubWF0Y2gucGFyYW1zLnBhcmFtSWQpIDogMFxuICAgICAgICB9O1xuXG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmhhbmRsZVBhZ2VDbGljayA9IF90aGlzLmhhbmRsZVBhZ2VDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlR3JpZEJ0bkNsaWNrID0gX3RoaXMuaGFuZGxlR3JpZEJ0bkNsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5idG5FZGl0Tm9tQ2xpY2sgPSBfdGhpcy5idG5FZGl0Tm9tQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmJ0bkVkaXRMYXBzQ2xpY2sgPSBfdGhpcy5idG5FZGl0TGFwc0NsaWNrLmJpbmQoX3RoaXMpO1xuXG4gICAgICAgIF90aGlzLnBhZ2VzID0gW3sgcGFnZU5hbWU6ICdMYXBzZSB0YWFiZWwnLCBkb2NUeXBlSWQ6ICdMQVBTRV9UQUFCRUwnIH1dO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKExhcHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG5cbiAgICAgICAgICAgIHZhciBpbml0RGF0YSA9IHRoaXMucHJvcHMuaW5pdERhdGEgPyB0aGlzLnByb3BzLmluaXREYXRhIDoge307XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50VGVtcGxhdGUsIHsgZG9jSWQ6IHRoaXMuc3RhdGUuZG9jSWQsXG4gICAgICAgICAgICAgICAgcmVmOiAnZG9jdW1lbnQnLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ0xBUFNFX1RBQUJFTCcsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnN0YXRlLm1vZHVsZSxcbiAgICAgICAgICAgICAgICBpbml0RGF0YTogaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgbGliczogTElCUkFSSUVTLFxuICAgICAgICAgICAgICAgIHBhZ2VzOiB0aGlzLnBhZ2VzLFxuICAgICAgICAgICAgICAgIHJlbmRlcmVyOiB0aGlzLnJlbmRlcmVyLFxuICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2ssXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5LFxuICAgICAgICAgICAgICAgIGZvY3VzRWxlbWVudDogJ2lucHV0LWtvb2QnXG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAq0JLQtdGA0L3QtdGCINC60LDRgdGC0L7QvNC90YvQtSDQutC+0LzQv9C+0L3QtdC90YLRiyDQtNC+0LrRg9C80LXQvdGC0LBcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgdmFyIGJwbSA9IHNlbGYuZG9jRGF0YSAmJiBzZWxmLmRvY0RhdGEuYnBtID8gc2VsZi5kb2NEYXRhLmJwbSA6IFtdLFxuICAgICAgICAgICAgICAgIGlzRWRpdE1vZGUgPSBzZWxmLnN0YXRlLmVkaXRlZDtcblxuICAgICAgICAgICAgaWYgKChzZWxmLmRvY0RhdGEuaWQgPT0gMCB8fCAhc2VsZi5kb2NEYXRhLnBhcmVudGlkKSAmJiB0aGlzLnN0YXRlLmxhcHNJZCkge1xuICAgICAgICAgICAgICAgIC8vbmV3IHJlY29yZFxuICAgICAgICAgICAgICAgIHNlbGYuZG9jRGF0YS5wYXJlbnRpZCA9IHRoaXMuc3RhdGUubGFwc0lkO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICB2YXIga3B2ID0gbmV3IERhdGUoKSxcbiAgICAgICAgICAgICAgICBrdXUgPSBrcHYuZ2V0TW9udGgoKSxcbiAgICAgICAgICAgICAgICBhYXN0YSA9IGtwdi5nZXRGdWxsWWVhcigpO1xuXG4gICAgICAgICAgICB2YXIgYnV0dG9uRWRpdE5vbSA9IHN0eWxlcy5idG5FZGl0Tm9tO1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChTZWxlY3REYXRhLCB7IHRpdGxlOiAnTGFwc2UgbmltaTonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdwYXJlbnRpZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbGliTmFtZTogJ2xhcHMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNxbEZpZWxkczogWyduaW1pJywgJ2lzaWt1a29vZCddLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IFtdLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEucGFyZW50aWQgfHwgMCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHNlbGYuZG9jRGF0YS5uaW1pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJvdW5kVG9HcmlkOiAnbmltaScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYm91bmRUb0RhdGE6ICduaW1pJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdzZWxlY3QtcGFyZW50aWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJ0bkRlbGV0ZTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdXNlckRhdGE6IHNlbGYudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQnV0dG9uRWRpdCwge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2J0bkVkaXQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2xpY2s6IHRoaXMuYnRuRWRpdExhcHNDbGljayxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzaG93OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZTogYnV0dG9uRWRpdE5vbSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnS29vZDonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdub21pZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbGliczogJ2xhcHNlX2thYXJ0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBzZWxmLmxpYnNbJ2xhcHNlX2thYXJ0J10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5ub21pZCB8fCAwLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlZmF1bHRWYWx1ZTogc2VsZi5kb2NEYXRhLmtvb2QsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LW5vbWlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBidG5EZWxldGU6IGlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQnV0dG9uRWRpdCwge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2J0bkVkaXQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2xpY2s6IHRoaXMuYnRuRWRpdE5vbUNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNob3c6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBidXR0b25FZGl0Tm9tLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgICAgICAgICAgICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dE51bWJlciwgeyByZWY6ICdpbnB1dC1rb2d1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdLb2d1czonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrb2d1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IE51bWJlcihzZWxmLmRvY0RhdGEua29ndXMpIHx8IE51bWJlcihudWxsKSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7IHJlZjogJ2lucHV0LWt1dScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdLdXU6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna3V1JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHNlbGYuZG9jRGF0YS5rdXUpIHx8IE51bWJlcihrdXUpLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgcmVmOiAnaW5wdXQtYWFzdGEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpdGxlOiAnQWFzdGE6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYWFzdGEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIoc2VsZi5kb2NEYXRhLmFhc3RhKSB8fCBOdW1iZXIoYWFzdGEpLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFRleHRBcmVhLCB7IHRpdGxlOiAnTVxceEU0cmt1c2VkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdtdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3RleHRhcmVhLW11dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLm11dWQgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUgfSlcbiAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdoYW5kbGVQYWdlQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaGFuZGxlUGFnZUNsaWNrKHBhZ2VEb2NUeXBlSWQpIHtcbiAgICAgICAgICAgIC8vICAgICAgICBkb2N1bWVudC5sb2NhdGlvbi5ocmVmID0gYC9sYXBzZWQvJHtwYWdlRG9jVHlwZUlkfS9gOy8vQHRvZG8g0J7QsdC90L7QstC40YLRjFxuICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goJy9sYXBzZWQvJyArIHBhZ2VEb2NUeXBlSWQpO1xuICAgICAgICB9XG5cbiAgICAgICAgLy8g0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0LrQu9C40Log0L3QsCDQs9GA0LjQtNC1INGA0L7QtNC40YLQtdC70LXQuVxuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdoYW5kbGVHcmlkQnRuQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaGFuZGxlR3JpZEJ0bkNsaWNrKGJ0bk5hbWUsIGFjdGl2ZVJvdywgaWQsIGRvY1R5cGVJZCkge1xuICAgICAgICAgICAgc3dpdGNoIChidG5OYW1lKSB7XG4gICAgICAgICAgICAgICAgY2FzZSBcImVkaXRcIjpcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goJy9sYXBzZWQvJyArIGRvY1R5cGVJZCArICcvJyArIGlkICsgJy8wJyk7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIGNhc2UgXCJhZGRcIjpcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goJy9sYXBzZWQvJyArIGRvY1R5cGVJZCArICcvMC8nICsgdGhpcy5zdGF0ZS5kb2NJZCk7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIGRlZmF1bHQ6XG4gICAgICAgICAgICAgICAgICAgIGNvbnNvbGUubG9nKCdWaWdhbmUgY2xpY2snKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIC8v0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0L/QviDQutC70LjQutGDINC60L3QvtC/0LrQuCDQoNC10LTQsNC60YLQuNGA0L7QstCw0L3QuNC1INGB0L3QvtC80LXQvdC60LvQsNGC0YPRgNGLXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2J0bkVkaXROb21DbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBidG5FZGl0Tm9tQ2xpY2soKSB7XG4gICAgICAgICAgICB2YXIgZG9jTm9tSWQgPSB0aGlzLnJlZnNbJ2RvY3VtZW50J10uZG9jRGF0YS5ub21pZDtcblxuICAgICAgICAgICAgLy8g0L7RgdGD0YnQtdGB0YLQstC40YIg0L/QtdGA0LXRhdC+0LQg0L3QsCDQutCw0YDRgtC+0YfQutGDINC60L7QvdGC0YAt0LDQs9C10L3RgtCwXG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC9ub21lbmNsYXR1cmUvJyArIGRvY05vbUlkKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8v0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0L/QviDQutC70LjQutGDINC60L3QvtC/0LrQuCDQoNC10LTQsNC60YLQuNGA0L7QstCw0L3QuNC1INGA0LXQsdC10L3QutCwXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2J0bkVkaXRMYXBzQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gYnRuRWRpdExhcHNDbGljaygpIHtcbiAgICAgICAgICAgIHZhciBkb2NMYXBzSWQgPSB0aGlzLnJlZnNbJ2RvY3VtZW50J10uZG9jRGF0YS5wYXJlbnRpZDtcblxuICAgICAgICAgICAgLy8g0L7RgdGD0YnQtdGB0YLQstC40YIg0L/QtdGA0LXRhdC+0LQg0L3QsCDQutCw0YDRgtC+0YfQutGDINC60L7QvdGC0YAt0LDQs9C10L3RgtCwXG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC9sYXBzLycgKyBkb2NMYXBzSWQpO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIExhcHM7XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5MYXBzLnByb3BUeXBlcyA9IHtcbiAgICBkb2NJZDogUHJvcFR5cGVzLm51bWJlcixcbiAgICBpbml0RGF0YTogUHJvcFR5cGVzLm9iamVjdCxcbiAgICB1c2VyRGF0YTogUHJvcFR5cGVzLm9iamVjdFxufTtcblxuTGFwcy5kZWZhdWx0UHJvcHMgPSB7XG4gICAgcGFyYW1zOiB7IGRvY0lkOiAwIH0sXG4gICAgaW5pdERhdGE6IHt9LFxuICAgIHVzZXJEYXRhOiB7fVxufTtcblxubW9kdWxlLmV4cG9ydHMgPSBMYXBzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzZV90YWFiZWwvZG9jdW1lbnQvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyMzlcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBkb2NSb3c6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAncm93J1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsdWUnXHJcbiAgICAgICAgKi9cbiAgICB9LFxuICAgIGRvY0NvbHVtbjoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nLFxuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIHllbGxvdycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgd2lkdGg6ICc1MCUnXG4gICAgfSxcbiAgICBkb2M6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJ1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJyb3duJ1xyXG4gICAgICAgICovXG4gICAgfSxcblxuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9LFxuXG4gICAgZ3JpZFJvdzoge1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsYWNrJyxcclxuICAgICAgICAqL1xuICAgICAgICBiYWNrZ3JvdW5kQ29sb3I6ICd3aGl0ZScsXG4gICAgICAgIHBvc2l0aW9uOiAncmVsYXRpdmUnLFxuICAgICAgICBtYXJnaW46ICcxMCUgMzAlIDEwJSAzMCUnLFxuICAgICAgICB3aWR0aDogJ2F1dG8nLFxuICAgICAgICBvcGFjaXR5OiAnMScsXG4gICAgICAgIHRvcDogJzEwMHB4J1xuICAgIH0sXG5cbiAgICBidG5FZGl0Tm9tOiB7XG4gICAgICAgIHdpZHRoOiAnbWluLWNvbnRlbnQnXG4gICAgfVxuXG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzZV90YWFiZWwvZG9jdW1lbnQvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyNDBcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBQcm9wVHlwZXMgPSByZXF1aXJlKCdwcm9wLXR5cGVzJyk7XG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xuXG52YXIgRG9jdW1lbnRUZW1wbGF0ZSA9IHJlcXVpcmUoJy4uLy4uL2RvY3VtZW50VGVtcGxhdGUvaW5kZXguanN4JyksXG4gICAgSW5wdXRUZXh0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC10ZXh0L2lucHV0LXRleHQuanN4JyksXG4gICAgU2VsZWN0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3Qvc2VsZWN0LmpzeCcpLFxuICAgIEJ1dHRvbkVkaXQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2J1dHRvbi1yZWdpc3Rlci9idXR0b24tcmVnaXN0ZXItZWRpdC9idXR0b24tcmVnaXN0ZXItZWRpdC5qc3gnKSxcbiAgICBTZWxlY3REYXRhID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3QtZGF0YS9zZWxlY3QtZGF0YS5qc3gnKSxcbiAgICBUZXh0QXJlYSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvdGV4dC1hcmVhL3RleHQtYXJlYS5qc3gnKSxcbiAgICBEYXRhR3JpZCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvZGF0YS1ncmlkL2RhdGEtZ3JpZC5qc3gnKSxcbiAgICBNb2RhbFBhZ2UgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL21vZGFscGFnZS9tb2RhbFBhZ2UuanN4JyksXG4gICAgc3R5bGVzID0gcmVxdWlyZSgnLi9zdHlsZXMnKTtcblxudmFyIExJQkRPSyA9ICdWQU5FTScsXG4gICAgTElCUkFSSUVTID0gW107XG5cbnZhciBub3cgPSBuZXcgRGF0ZSgpO1xuXG52YXIgVmFuZW0gPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoVmFuZW0sIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIFZhbmVtKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBWYW5lbSk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKFZhbmVtLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoVmFuZW0pKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMuc3RhdGUgPSB7XG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCksXG4gICAgICAgICAgICBsYXBzSWQ6IG51bGwsXG4gICAgICAgICAgICBtb2R1bGU6ICdsYXBzZWQnXG4gICAgICAgIH07XG5cbiAgICAgICAgX3RoaXMucmVuZGVyZXIgPSBfdGhpcy5yZW5kZXJlci5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlUGFnZUNsaWNrID0gX3RoaXMuaGFuZGxlUGFnZUNsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5oYW5kbGVMYXN0ZUdyaWRCdG5DbGljayA9IF90aGlzLmhhbmRsZUxhc3RlR3JpZEJ0bkNsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5idG5FZGl0QXN1dHVzQ2xpY2sgPSBfdGhpcy5idG5FZGl0QXN1dHVzQ2xpY2suYmluZChfdGhpcyk7XG5cbiAgICAgICAgX3RoaXMucGFnZXMgPSBbeyBwYWdlTmFtZTogJ1ZhbmVtIGthYXJ0JywgZG9jVHlwZUlkOiAnVkFORU0nIH0sIHsgcGFnZU5hbWU6ICdBcnZlZCcsIGhhbmRsZVBhZ2VDbGljazogX3RoaXMuaGFuZGxlUGFnZUNsaWNrLCBkb2NUeXBlSWQ6ICdBUlYnIH0sIHsgcGFnZU5hbWU6ICdNYWtzZWtvcmFsZHVzZWQnLCBoYW5kbGVQYWdlQ2xpY2s6IF90aGlzLmhhbmRsZVBhZ2VDbGljaywgZG9jVHlwZUlkOiAnU01LJyB9LCB7IHBhZ2VOYW1lOiAnS2Fzc2FvcmRlcmlkJywgaGFuZGxlUGFnZUNsaWNrOiBfdGhpcy5oYW5kbGVQYWdlQ2xpY2ssIGRvY1R5cGVJZDogJ1NPUkRFUicgfV07XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoVmFuZW0sIFt7XG4gICAgICAgIGtleTogJ2NvbXBvbmVudERpZE1vdW50JyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGNvbXBvbmVudERpZE1vdW50KCkge1xuICAgICAgICAgICAgaWYgKHRoaXMucHJvcHMuaGlzdG9yeSAmJiB0aGlzLnByb3BzLmhpc3RvcnkubG9jYXRpb24uc3RhdGUpIHtcbiAgICAgICAgICAgICAgICB2YXIgbGFwc0lkID0gdGhpcy5wcm9wcy5oaXN0b3J5LmxvY2F0aW9uLnN0YXRlLmxhcHNJZDtcbiAgICAgICAgICAgICAgICB2YXIgX21vZHVsZSA9IHRoaXMucHJvcHMuaGlzdG9yeS5sb2NhdGlvbi5zdGF0ZS5tb2R1bGU7XG4gICAgICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IGxhcHNJZDogbGFwc0lkLCBtb2R1bGU6IF9tb2R1bGUgfSk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICB2YXIgaW5pdERhdGEgPSB0aGlzLnByb3BzLmluaXREYXRhID8gdGhpcy5wcm9wcy5pbml0RGF0YSA6IHt9O1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFRlbXBsYXRlLCB7IGRvY0lkOiB0aGlzLnN0YXRlLmRvY0lkLFxuICAgICAgICAgICAgICAgIHJlZjogJ2RvY3VtZW50JyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6ICdWQU5FTScsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnN0YXRlLm1vZHVsZSxcbiAgICAgICAgICAgICAgICB1c2VyRGF0YTogdGhpcy5wcm9wcy51c2VyRGF0YSxcbiAgICAgICAgICAgICAgICBpbml0RGF0YTogaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgbGliczogTElCUkFSSUVTLFxuICAgICAgICAgICAgICAgIHBhZ2VzOiB0aGlzLnBhZ2VzLFxuICAgICAgICAgICAgICAgIHJlbmRlcmVyOiB0aGlzLnJlbmRlcmVyLFxuICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogdGhpcy5oYW5kbGVMYXN0ZUdyaWRCdG5DbGljayxcbiAgICAgICAgICAgICAgICBmb2N1c0VsZW1lbnQ6ICdpbnB1dC1pc2lrdWtvb2QnXG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAq0JLQtdGA0L3QtdGCINC60LDRgdGC0L7QvNC90YvQtSDQutC+0LzQv9C+0L3QtdC90YLRiyDQtNC+0LrRg9C80LXQvdGC0LBcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgdmFyIGlzRWRpdE1vZGUgPSBzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICBncmlkTGFzdGVEYXRhID0gc2VsZi5kb2NEYXRhLmxhcHNlZCxcbiAgICAgICAgICAgICAgICBncmlkTGFzdGVDb2x1bW5zID0gc2VsZi5kb2NEYXRhLmdyaWRDb25maWc7XG5cbiAgICAgICAgICAgIGlmICh0aGlzLnN0YXRlLmxhcHNJZCkge1xuICAgICAgICAgICAgICAgIHNlbGYuZG9jRGF0YS5wYXJlbnRpZCA9IHRoaXMuc3RhdGUubGFwc0lkO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChTZWxlY3REYXRhLCB7IHRpdGxlOiAnVmFuZW06JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYXN1dHVzaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYk5hbWU6ICdhc3V0dXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc3FsRmllbGRzOiBbJ25pbWV0dXMnLCAncmVna29vZCddLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IFtdLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuYXN1dHVzaWQgfHwgMCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHNlbGYuZG9jRGF0YS52YW5lbV9uaW1pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJvdW5kVG9HcmlkOiAnbmltZXR1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYm91bmRUb0RhdGE6ICd2YW5lbV9uaW1pJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdzZWxlY3QtYXN1dHVzaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJ0bkRlbGV0ZTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdXNlckRhdGE6IHNlbGYudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQnV0dG9uRWRpdCwge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2J0bkVkaXQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2xpY2s6IHRoaXMuYnRuRWRpdEFzdXR1c0NsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNob3c6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMuYnRuRWRpdCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnU3VndWx1czonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdzdWh0dW1pbmUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuc3VodHVtaW5lIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXN1aHR1bWluZScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChTZWxlY3QsIHsgdGl0bGU6ICdBcnZlbGR1czonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdhcnZlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogW3sgbmFtZTogJ0phaCcgfSwgeyBuYW1lOiAnRWknIH1dLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuYXJ2ZWQgfHwgJ0VpJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xsSWQ6ICduYW1lJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHNlbGYuZG9jRGF0YS5hcnZlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdzZWxlY3QtYXJ2ZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJ0bkRlbGV0ZTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdNXFx4RTRya3VzZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ211dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubXV1ZCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdsYWJlbCcsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ2xhYmVsJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgJ0xhcHNlZCdcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEYXRhR3JpZCwgeyBzb3VyY2U6ICdsYXBzZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZERhdGE6IGdyaWRMYXN0ZURhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICBncmlkQ29sdW1uczogZ3JpZExhc3RlQ29sdW1ucyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHNob3dUb29sQmFyOiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogc2VsZi5oYW5kbGVHcmlkQnRuQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLmdyaWQuaGVhZGVyVGFibGUsXG4gICAgICAgICAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6ICdsYXBzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2xhc3BzZWQtZGF0YS1ncmlkJyB9KVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVBhZ2VDbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVQYWdlQ2xpY2socGFnZURvY1R5cGVJZCkge1xuICAgICAgICAgICAgdmFyIG5pbWkgPSB0aGlzLnJlZnNbJ2RvY3VtZW50J10uZG9jRGF0YS52YW5lbV9uaW1pO1xuXG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCh7XG4gICAgICAgICAgICAgICAgcGF0aG5hbWU6ICcvbGFwc2VkLycgKyBwYWdlRG9jVHlwZUlkLFxuICAgICAgICAgICAgICAgIHN0YXRlOiB7IGFzdXR1czogbmltaSwgdHlwZTogJ3RleHQnIH1cbiAgICAgICAgICAgIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdoYW5kbGVMYXN0ZUdyaWRCdG5DbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVMYXN0ZUdyaWRCdG5DbGljayhidG5OYW1lLCBhY3RpdmVSb3csIGlkLCBkb2NUeXBlSWQpIHtcblxuICAgICAgICAgICAgc3dpdGNoIChidG5OYW1lKSB7XG4gICAgICAgICAgICAgICAgY2FzZSBcImVkaXRcIjpcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goe1xuICAgICAgICAgICAgICAgICAgICAgICAgcGF0aG5hbWU6ICcvbGFwc2VkLycgKyBkb2NUeXBlSWQgKyAnLycgKyBpZCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHN0YXRlOiB7IHZhbmVtSWQ6IHRoaXMuc3RhdGUuZG9jSWQsIG1vZHVsZTogdGhpcy5zdGF0ZS5tb2R1bGUgfVxuICAgICAgICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICBjYXNlIFwiYWRkXCI6XG4gICAgICAgICAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHBhdGhuYW1lOiAnL2xhcHNlZC8nICsgZG9jVHlwZUlkICsgJy8wJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHN0YXRlOiB7IHZhbmVtSWQ6IHRoaXMuc3RhdGUuZG9jSWQsIG1vZHVsZTogdGhpcy5zdGF0ZS5tb2R1bGUgfVxuICAgICAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgY2FzZSBcImRlbGV0ZVwiOlxuICAgICAgICAgICAgICAgICAgICBjb25zb2xlLmxvZygnYnRuRGVsZXRlIGNsaWNrZWQnKTtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgZGVmYXVsdDpcbiAgICAgICAgICAgICAgICAgICAgY29uc29sZS5sb2coJ1ZpZ2FuZSBjbGljaycpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgLy8g0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0LrQu9C40YHQutCwINC90LAg0LrQvdC+0L/QutC1INGA0LXQtNCw0LrRgtC40YDQvtCy0LDQvdC40Y8g0LrQvtC90YLRgC3QsNCz0LXQvdGC0LBcblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnYnRuRWRpdEFzdXR1c0NsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGJ0bkVkaXRBc3V0dXNDbGljaygpIHtcbiAgICAgICAgICAgIHZhciBkb2NBc3V0dXNJZCA9IHRoaXMucmVmc1snZG9jdW1lbnQnXS5kb2NEYXRhLmFzdXR1c2lkO1xuXG4gICAgICAgICAgICAvLyDQvtGB0YPRidC10YHRgtCy0LjRgiDQv9C10YDQtdGF0L7QtCDQvdCwINC60LDRgNGC0L7Rh9C60YMg0LrQvtC90YLRgC3QsNCz0LXQvdGC0LBcbiAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKCcvbGFwc2VkL2FzdXR1c2VkLycgKyBkb2NBc3V0dXNJZCk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gVmFuZW07XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5WYW5lbS5wcm9wVHlwZXMgPSB7XG4gICAgZG9jSWQ6IFByb3BUeXBlcy5udW1iZXIsXG4gICAgaW5pdERhdGE6IFByb3BUeXBlcy5vYmplY3QsXG4gICAgdXNlckRhdGE6IFByb3BUeXBlcy5vYmplY3Rcbn07XG5cblZhbmVtLmRlZmF1bHRQcm9wcyA9IHtcbiAgICBwYXJhbXM6IHsgZG9jSWQ6IDAgfSxcbiAgICBpbml0RGF0YToge30sXG4gICAgdXNlckRhdGE6IHt9XG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IFZhbmVtO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy92YW5lbS9kb2N1bWVudC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDI0MVxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGRvY1Jvdzoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdyb3cnXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYmx1ZSdcclxuICAgICAgICAqL1xuICAgIH0sXG4gICAgZG9jQ29sdW1uOiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ2NvbHVtbicsXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgeWVsbG93JyxcclxuICAgICAgICAqL1xuICAgICAgICB3aWR0aDogJzUwJSdcbiAgICB9LFxuICAgIGRvYzoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYnJvd24nXHJcbiAgICAgICAgKi9cbiAgICB9LFxuXG4gICAgZ3JpZDoge1xuICAgICAgICBtYWluVGFibGU6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfSxcbiAgICAgICAgaGVhZGVyVGFibGU6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfSxcblxuICAgICAgICBncmlkQ29udGFpbmVyOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH1cblxuICAgIH0sXG5cbiAgICBncmlkUm93OiB7XG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYmxhY2snLFxyXG4gICAgICAgICovXG4gICAgICAgIGJhY2tncm91bmRDb2xvcjogJ3doaXRlJyxcbiAgICAgICAgcG9zaXRpb246ICdyZWxhdGl2ZScsXG4gICAgICAgIG1hcmdpbjogJzEwJSAzMCUgMTAlIDMwJScsXG4gICAgICAgIHdpZHRoOiAnYXV0bycsXG4gICAgICAgIG9wYWNpdHk6ICcxJyxcbiAgICAgICAgdG9wOiAnMTAwcHgnXG4gICAgfSxcblxuICAgIGJ0bkVkaXQ6IHtcbiAgICAgICAgd2lkdGg6ICdtaW4tY29udGVudCdcbiAgICB9XG5cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL3ZhbmVtL2RvY3VtZW50L3N0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjQyXG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIERvY3VtZW50UmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3VtZW50cy9kb2N1bWVudHMuanN4Jyk7XG52YXIgc3R5bGVzID0gcmVxdWlyZSgnLi9zdHlsZXMnKTtcbnZhciBET0NfVFlQRV9JRCA9ICdWQU5FTSc7XG52YXIgdG9vbGJhclBhcmFtcyA9IHtcbiAgICBidG5BZGQ6IHtcbiAgICAgICAgc2hvdzogZmFsc2UsXG4gICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgIH0sXG4gICAgYnRuRWRpdDoge1xuICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICB9LFxuICAgIGJ0bkRlbGV0ZToge1xuICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICB9LFxuICAgIGJ0blByaW50OiB7XG4gICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgIH1cbn07XG5cbi8qKlxyXG4gKiDQmtC70LDRgdGBINGA0LXQsNC70LjQt9GD0LXRgiDQtNC+0LrRg9C80LXQvdGCINGB0L/RgNCw0LLQvtGH0L3QuNC60LAg0L/RgNC40LfQvdCw0LrQvtCyLlxyXG4gKi9cblxudmFyIERvY3VtZW50cyA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhEb2N1bWVudHMsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIERvY3VtZW50cyhwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgRG9jdW1lbnRzKTtcblxuICAgICAgICByZXR1cm4gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKERvY3VtZW50cy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKERvY3VtZW50cykpLmNhbGwodGhpcywgcHJvcHMpKTtcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoRG9jdW1lbnRzLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFJlZ2lzdGVyLCB7IGluaXREYXRhOiB0aGlzLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgIHVzZXJEYXRhOiB0aGlzLnByb3BzLnVzZXJEYXRhLFxuICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSA/IHRoaXMucHJvcHMuaGlzdG9yeSA6IG51bGwsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnByb3BzLm1vZHVsZSxcbiAgICAgICAgICAgICAgICByZWY6ICdyZWdpc3RlcicsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiBET0NfVFlQRV9JRCxcbiAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLFxuICAgICAgICAgICAgICAgIHRvb2xiYXJQYXJhbXM6IHRvb2xiYXJQYXJhbXMsXG4gICAgICAgICAgICAgICAgcmVuZGVyOiB0aGlzLnJlbmRlcmVyIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgJ1ZhbmVtYXRlIHJlZ2lzdGVyIHNwZWNpYWwgcmVuZGVyJ1xuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBEb2N1bWVudHM7XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5tb2R1bGUuZXhwb3J0cyA9IERvY3VtZW50cztcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvdmFuZW0vaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyNDNcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBncmlkOiB7XG4gICAgICAgIG1haW5UYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuICAgICAgICBoZWFkZXJUYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuXG4gICAgICAgIGdyaWRDb250YWluZXI6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfVxuXG4gICAgfVxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvdmFuZW0vc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyNDRcbi8vIG1vZHVsZSBjaHVua3MgPSAwIl0sIm1hcHBpbmdzIjoiOzs7Ozs7QUFBQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzlCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDN01BO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDclRBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNwREE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDckRBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNoQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUN0REE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2hCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDL1RBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNuSEE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDcEJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDNURBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ3JEQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDaEJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDclFBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ3hEQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzVQQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUN4REE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDMUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Iiwic291cmNlUm9vdCI6IiJ9