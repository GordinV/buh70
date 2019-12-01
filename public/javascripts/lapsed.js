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
	var JournalDocument = __webpack_require__(168);

	var LapseDokument = __webpack_require__(223);
	var LasteRegister = __webpack_require__(225);

	var LasteTeenustRegister = __webpack_require__(234);
	var LapseKaartDokument = __webpack_require__(236);

	var LasteTaabelRegister = __webpack_require__(242);
	var LapseTaabelDokument = __webpack_require__(245);

	var VanemDokument = __webpack_require__(247);
	var VanemateRegister = __webpack_require__(249);

	var ArvedeRegister = __webpack_require__(251);
	var ArveDocument = __webpack_require__(255);

	var SmkRegister = __webpack_require__(257);
	var SmkDocument = __webpack_require__(262);

	var SorderideRegister = __webpack_require__(266);
	var SorderDocument = __webpack_require__(268);

	var NomRegister = __webpack_require__(270),
	    NomDocument = __webpack_require__(272);

	var TunnusRegister = __webpack_require__(274),
	    TunnusDocument = __webpack_require__(276);

	var AsutusRegister = __webpack_require__(278),
	    AsutusDocument = __webpack_require__(280);

	var LapseGruppRegister = __webpack_require__(282),
	    LapseGruppDocument = __webpack_require__(284);

	var PankVVRegister = __webpack_require__(286);
	var ConfigDocument = __webpack_require__(288);
	var RekvDocument = __webpack_require__(290);
	var DokpropsDocument = __webpack_require__(292);
	var UserDocument = __webpack_require__(294);

	var Inf3Report = __webpack_require__(296);
	var ChildSummaryReport = __webpack_require__(298);
	var ArvedKoodiJargiReport = __webpack_require__(300);
	var SaldoJaKaiveReport = __webpack_require__(302);
	var SentDocsReport = __webpack_require__(327);

	var _require = __webpack_require__(4),
	    Route = _require.Route,
	    Redirect = _require.Redirect;

	var _require2 = __webpack_require__(91),
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

	            var btnParams = this.prepareParamsForToolbar();
	            return React.createElement(
	                StyleRoot,
	                null,
	                React.createElement(Route, { path: '/lapsed',
	                    render: function render() {
	                        return React.createElement(Menu, { params: btnParams,
	                            history: _this2.props.history,
	                            rekvId: DocContext.userData ? DocContext.userData.asutusId : 0,
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
	                React.createElement(Route, { exact: true, path: '/lapsed/laps/:docId',
	                    render: function render(props) {
	                        return React.createElement(LapseDokument, _extends({}, props, { history: props.history }));
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/asutused',
	                    render: function render(props) {
	                        return React.createElement(AsutusRegister, {
	                            history: props.history,
	                            initData: _this2.props.initData,
	                            module: MODULE });
	                    }
	                }),
	                React.createElement(Route, { exact: true, path: '/lapsed/asutused/:docId',
	                    render: function render(props) {
	                        return React.createElement(AsutusDocument, _extends({}, props, { history: props.history }));
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/lapse_grupp',
	                    render: function render(props) {
	                        return React.createElement(LapseGruppRegister, {
	                            history: props.history,
	                            initData: _this2.props.initData,
	                            module: MODULE });
	                    }
	                }),
	                React.createElement(Route, { exact: true, path: '/lapsed/lapse_grupp/:docId',
	                    render: function render(props) {
	                        return React.createElement(LapseGruppDocument, _extends({}, props, { history: props.history }));
	                    } }),
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
	                React.createElement(Route, { exact: true, path: '/lapsed/smk/:docId',
	                    render: function render(props) {
	                        return React.createElement(SmkDocument, _extends({}, props, { history: props.history }));
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/sorder',
	                    render: function render(props) {
	                        return React.createElement(SorderideRegister, {
	                            history: props.history,
	                            initData: _this2.props.initData,
	                            module: MODULE });
	                    }
	                }),
	                React.createElement(Route, { exact: true, path: '/lapsed/sorder/:docId',
	                    render: function render(props) {
	                        return React.createElement(SorderDocument, _extends({}, props, { history: props.history }));
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/nomenclature',
	                    render: function render(props) {
	                        return React.createElement(NomRegister, { history: props.history,
	                            initData: _this2.props.initData, module: MODULE });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/nomenclature/:docId',
	                    render: function render(props) {
	                        return React.createElement(NomDocument, _extends({}, props, {
	                            module: MODULE,
	                            history: props.history
	                        }));
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/tunnus/:docId', component: TunnusDocument }),
	                React.createElement(Route, { exact: true, path: '/lapsed/tunnus',
	                    render: function render(props) {
	                        return React.createElement(TunnusRegister, {
	                            module: MODULE,
	                            history: props.history,
	                            initData: _this2.props.initData });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/pank_vv',
	                    render: function render(props) {
	                        return React.createElement(PankVVRegister, {
	                            module: MODULE,
	                            history: props.history,
	                            initData: _this2.props.initData });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/config/:docId',
	                    render: function render(props) {
	                        return React.createElement(ConfigDocument, _extends({}, props, { history: props.history }));
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/config',
	                    render: function render(props) {
	                        return React.createElement(Redirect, { to: '/lapsed/config/' + DocContext.userData.asutusId });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/rekv/:docId',
	                    render: function render(props) {
	                        return React.createElement(RekvDocument, _extends({}, props, { history: props.history }));
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/rekv',
	                    render: function render(props) {
	                        return React.createElement(Redirect, { to: '/lapsed/rekv/' + DocContext.userData.asutusId });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/dokprops/:docId',
	                    render: function render(props) {
	                        return React.createElement(DokpropsDocument, _extends({}, props, { history: props.history }));
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/userid/:docId',
	                    render: function render(props) {
	                        return React.createElement(UserDocument, _extends({}, props, { history: props.history }));
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/userid/',
	                    render: function render(props) {
	                        return React.createElement(Redirect, { to: '/lapsed/userid/' + DocContext.userData.id });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/inf3',
	                    render: function render(props) {
	                        return React.createElement(Inf3Report, {
	                            module: MODULE,
	                            history: props.history,
	                            initData: _this2.props.initData });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/laps_kokkuvotte',
	                    render: function render(props) {
	                        return React.createElement(ChildSummaryReport, {
	                            module: MODULE,
	                            history: props.history,
	                            initData: _this2.props.initData });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/arved_koodi_jargi',
	                    render: function render(props) {
	                        return React.createElement(ArvedKoodiJargiReport, {
	                            module: MODULE,
	                            history: props.history,
	                            initData: _this2.props.initData });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/saldo_ja_kaive',
	                    render: function render(props) {
	                        return React.createElement(SaldoJaKaiveReport, {
	                            module: MODULE,
	                            history: props.history,
	                            initData: _this2.props.initData });
	                    } }),
	                React.createElement(Route, { exact: true, path: '/lapsed/sent_docs',
	                    render: function render(props) {
	                        return React.createElement(SentDocsReport, {
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
	                var LapseDocument = __webpack_require__(223);
	                return React.createElement(LapseDocument, props);
	            };
	        }
	    }]);

	    return App;
	}(React.Component);

	module.exports = App;

/***/ }),

/***/ 223:
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

	var DocumentTemplate = __webpack_require__(169),
	    InputText = __webpack_require__(212),
	    TextArea = __webpack_require__(219),
	    DataGrid = __webpack_require__(184),
	    styles = __webpack_require__(224);

	var LIBRARIES = [];

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

	            //сохраним последний docId
	            if (this.state.docId) {
	                DocContext.lapsId = this.state.docId;
	            }
	        }
	    }, {
	        key: 'render',
	        value: function render() {

	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                history: this.props.history,
	                module: this.state.module,
	                docTypeId: 'LAPS',
	                initData: this.props.initData ? this.props.initData : {},
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
	            var isEditMode = self.state.edited,
	                gridVanemadData = self.docData.vanemad,
	                gridVanemadColumns = self.docData.gridConfig,
	                gridTeenusteData = self.docData.teenused,
	                gridTeenusteColumns = self.docData.gridTeenusteConfig;

	            if (self.docData.id === 0) {
	                //neew record
	                self.docData.vanemid = this.state.vanemId;
	            }

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
	                            readOnly: true,
	                            disabled: true,
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
	                        handleGridBtnClick: self.handleGridBtnClick,
	                        readOnly: isEditMode,
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

	            switch (btnName.toUpperCase()) {
	                case "EDIT":

	                    this.props.history.push({
	                        pathname: '/lapsed/' + docTypeId + '/' + id,
	                        state: { lapsId: this.docId, module: this.state.module }
	                    });
	                    break;
	                case "ADD":
	                    this.props.history.push({
	                        pathname: '/lapsed/' + docTypeId + '/0',
	                        state: { lapsId: this.docId, module: this.state.module }
	                    });
	                    break;
	                case "DELETE":
	                    //send post to delete row
	                    this.fetchData(docTypeId, id).then(function () {

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

/***/ 224:
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

/***/ 225:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);
	var BtnArvesta = __webpack_require__(232);
	var ToolbarContainer = __webpack_require__(79);

	var styles = __webpack_require__(233);
	var DOC_TYPE_ID = 'LAPS';
	var EVENTS = [{ name: 'Tabeli koostamine', method: 'arvestaTaabel', docTypeId: 'lapse_taabel' }, { name: 'Arve koostamine', method: 'koostaArve', docTypeId: 'arv' }, { name: 'Ettemaksuarve koostamine', method: 'koostaEttemaksuArve', docTypeId: 'arv' }];

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        var _this = _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));

	        _this.onClickHandler = _this.onClickHandler.bind(_this);
	        _this.renderer = _this.renderer.bind(_this);
	        return _this;
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
	            var _this2 = this;

	            return React.createElement(
	                ToolbarContainer,
	                null,
	                EVENTS.map(function (event) {
	                    return React.createElement(BtnArvesta, {
	                        value: event.name,
	                        onClick: _this2.onClickHandler,
	                        ref: 'btn-' + event.name
	                    });
	                })
	            );
	        }
	    }, {
	        key: 'onClickHandler',
	        value: function onClickHandler(event, seisuga) {
	            var _this3 = this;

	            var Doc = this.refs['register'];

	            // собираем параметры
	            var ids = [];
	            Doc.gridData.filter(function (row) {
	                return row.select;
	            }).forEach(function (row) {
	                ids.push(row.id);
	            });

	            var task = EVENTS.find(function (task) {
	                return task.name === event;
	            });
	            if (!task) {
	                return Doc.setState({ warning: 'Task: ' + event + ' ei leidnud', warningType: 'error' });
	            }

	            // отправляем запрос на выполнение
	            Doc.fetchData('calc/' + task.method, { docs: ids, seisuga: seisuga }).then(function (data) {
	                if (data.result) {
	                    Doc.setState({ warning: 'Kokku arvestatud: ' + data.result + ', suunatamine...', warningType: 'ok' });

	                    // ждем 10 сек и редайрект на табеля
	                    setTimeout(function () {
	                        _this3.props.history.push('/lapsed/' + task.docTypeId);
	                    }, 1000 * 5);
	                } else {
	                    Doc.setState({ warning: 'Tekkis viga: ' + data.error_message, warningType: 'notValid' });
	                }
	            });
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 232:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var PropTypes = __webpack_require__(32);
	var getNow = __webpack_require__(204);

	var ModalPage = __webpack_require__(180);

	var styles = __webpack_require__(82),
	    Button = __webpack_require__(83),
	    InputDate = __webpack_require__(208),
	    InputNumber = __webpack_require__(214),
	    ICON = 'execute';

	var ButtonTask = function (_React$PureComponent) {
	    _inherits(ButtonTask, _React$PureComponent);

	    // кнопка создания документа в регистрах
	    function ButtonTask(props) {
	        _classCallCheck(this, ButtonTask);

	        var _this = _possibleConstructorReturn(this, (ButtonTask.__proto__ || Object.getPrototypeOf(ButtonTask)).call(this, props));

	        _this.state = {
	            showModal: false,
	            seisuga: getNow(),
	            kogus: 0
	        };
	        _this.handleClick = _this.handleClick.bind(_this);
	        _this.modalPageClick = _this.modalPageClick.bind(_this);
	        _this.handleInputChange = _this.handleInputChange.bind(_this);
	        return _this;
	    }

	    _createClass(ButtonTask, [{
	        key: 'handleClick',
	        value: function handleClick(e) {
	            this.setState({ showModal: true });
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var value = this.props.value ? this.props.value : 'Täitmine';
	            return React.createElement(
	                'div',
	                null,
	                React.createElement(
	                    Button,
	                    {
	                        show: true,
	                        value: value,
	                        ref: 'btnTask',
	                        style: styles.button,
	                        disabled: false,
	                        onClick: this.handleClick },
	                    React.createElement('img', { ref: 'image', src: styles.icons[ICON] })
	                ),
	                this.state.showModal ? React.createElement(
	                    ModalPage,
	                    {
	                        modalPageBtnClick: this.modalPageClick,
	                        modalPageName: value,
	                        show: true,
	                        modalObjects: ['btnOk', 'btnCancel']
	                    },
	                    'Kas k\xE4ivata "' + value + '" ?',
	                    this.props.showDate ? React.createElement(InputDate, { title: 'Seisuga ',
	                        name: 'kpv',
	                        value: this.state.seisuga,
	                        ref: 'input-kpv',
	                        readOnly: false,
	                        onChange: this.handleInputChange }) : null,
	                    this.props.showKogus ? React.createElement(InputNumber, { title: this.props.title ? this.props.title : 'Väärtus',
	                        name: 'kogus',
	                        value: Number(this.state.kogus),
	                        ref: 'input-kogus',
	                        readOnly: false,
	                        onChange: this.handleInputChange }) : null
	                ) : null
	            );
	        }
	    }, {
	        key: 'modalPageClick',
	        value: function modalPageClick(btnEvent) {
	            this.setState({ showModal: false });
	            if (btnEvent === 'Ok') {
	                this.props.onClick(this.props.value, this.props.showKogus ? this.state.kogus : this.state.seisuga);
	            }
	        }

	        //will save value

	    }, {
	        key: 'handleInputChange',
	        value: function handleInputChange(name, value) {
	            switch (name) {
	                case 'kpv':
	                    this.setState({ seisuga: value });
	                    break;
	                case 'kogus':
	                    this.setState({ kogus: value });
	                    break;

	            }
	        }
	    }]);

	    return ButtonTask;
	}(React.PureComponent);

	ButtonTask.defaultProps = {
	    disabled: false,
	    show: true,
	    showDate: true,
	    showKogus: false
	};

	module.exports = ButtonTask;

/***/ }),

/***/ 233:
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

/***/ 234:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);
	var BtnTask = __webpack_require__(232);
	var ToolbarContainer = __webpack_require__(79);

	var styles = __webpack_require__(235);
	var DOC_TYPE_ID = 'LAPSE_KAART';

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        var _this = _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));

	        _this.onClickHandler = _this.onClickHandler.bind(_this);
	        _this.renderer = _this.renderer.bind(_this);
	        return _this;
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
	                ToolbarContainer,
	                null,
	                React.createElement(BtnTask, {
	                    value: 'Muuda ettemaksu period',
	                    onClick: this.onClickHandler,
	                    showDate: false,
	                    showKogus: true,
	                    ref: 'btn-ettemaksu_period'
	                })
	            );
	        }
	    }, {
	        key: 'onClickHandler',
	        value: function onClickHandler(event, ettemaksuPeriod) {
	            var Doc = this.refs['register'];

	            // собираем параметры
	            var ids = [];
	            Doc.gridData.filter(function (row) {
	                if (row.ettemaks && row.select) {
	                    return row;
	                }
	            }).forEach(function (row) {
	                ids.push(row.id);
	            });

	            // отправляем запрос на выполнение
	            Doc.fetchData('calc/muuda_ettemaksu_period', { docs: ids, ettemaksuPeriod: ettemaksuPeriod }).then(function (data) {

	                if (data.result) {
	                    Doc.setState({ warning: 'Kokku arvestatud: ' + data.result, warningType: 'ok' });
	                } else {
	                    Doc.setState({ warning: 'Tekkis viga: ' + data.error_message, warningType: 'notValid' });
	                }
	            });
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 235:
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

/***/ 236:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(32);
	var React = __webpack_require__(9);
	var DocContext = __webpack_require__(1);

	var DocumentTemplate = __webpack_require__(169),
	    InputNumber = __webpack_require__(214),
	    ButtonEdit = __webpack_require__(85),
	    InputDate = __webpack_require__(208),
	    Select = __webpack_require__(206),
	    CheckBox = __webpack_require__(237),
	    SelectData = __webpack_require__(239),
	    TextArea = __webpack_require__(219),
	    styles = __webpack_require__(241);

	var LIBRARIES = [{
	    id: 'tunnus', filter: ''
	}, {
	    id: 'nomenclature',
	    filter: 'where dok = \'ARV\''
	}, {
	    id: 'lapse_grupp',
	    filter: ''
	}];

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

	        _this.renderer = _this.renderer.bind(_this);
	        _this.handlePageClick = _this.handlePageClick.bind(_this);
	        _this.handleGridBtnClick = _this.handleGridBtnClick.bind(_this);
	        _this.btnEditNomClick = _this.btnEditNomClick.bind(_this);
	        _this.btnEditLapsClick = _this.btnEditLapsClick.bind(_this);
	        _this.btnEditLapseGruppClick = _this.btnEditLapseGruppClick.bind(_this);
	        _this.handleInputChange = _this.handleInputChange.bind(_this);

	        _this.pages = [{ pageName: 'Teenus', docTypeId: 'LAPSE_KAART' }];

	        _this.libs = {}; // libs cache
	        return _this;
	    }

	    _createClass(Laps, [{
	        key: 'componentDidMount',
	        value: function componentDidMount() {
	            var lapsId = void 0;

	            //если параметр на ребенка задан в стейте, то используем его. Иначе ищем его в контексте
	            if (this.props.history && this.props.history.location.state) {
	                lapsId = this.props.history.location.state.lapsId;
	            } else {
	                lapsId = DocContext['laps'] ? DocContext['laps'] : null;
	            }
	            this.setState({ lapsId: lapsId });
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
	                handleInputChange: this.handleInputChange,
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
	            var isEditMode = self.state.edited;

	            if ((!Number(self.docData.id) || !self.docData.parentid) && this.state.lapsId) {
	                //new record
	                self.docData.parentid = this.state.lapsId;
	            }

	            var buttonEditNom = styles.btnEditNom;

	            var yksus = void 0;
	            if (self.libs['lapse_grupp'] && self.docData.yksus) {
	                yksus = self.libs['lapse_grupp'].find(function (yksus) {
	                    return yksus.kood === self.docData.yksus;
	                });
	            }
	            var all_yksused = (yksus ? yksus.all_yksused : []).map(function (item, index) {
	                return { id: index++, nimetus: item };
	            });

	            // фильтр на номенклатуры
	            var nomData = [{ id: 0, kood: '', nimetus: '', hind: 0, kogus: 0, kas_inf3: false }];
	            // берем только услуги для группы, добавляяем цену и ед.измерения и сортируем
	            try {
	                if (yksus) {
	                    nomData = (yksus.teenused && self.libs['nomenclature'].length > 0 ? yksus.teenused : []).map(function (nom) {
	                        var row = self.libs['nomenclature'].find(function (lib) {
	                            return lib.id === Number(nom.nomid);
	                        });

	                        if (row) {
	                            var teenuseNimetus = row.nimetus ? row.nimetus + ' (hind: ' + Number(nom.hind).toFixed(2) + ') ' : '';
	                            return _extends({}, row, { nimetus: teenuseNimetus, id: Number(nom.nomid) });
	                        }
	                    }).sort(function (a, b) {
	                        return a.kood.localeCompare(b.kood);
	                    });
	                }
	            } catch (e) {
	                console.error(e, nomData);
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
	                            history: this.props.history,
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
	                        React.createElement(Select, { title: '\xDCksus:',
	                            name: 'yksus',
	                            libs: 'lapse_grupp',
	                            data: self.libs['lapse_grupp'],
	                            value: self.docData.yksus || '',
	                            defaultValue: self.docData.yksys || '',
	                            ref: 'select-lapse_grupp',
	                            collId: 'kood',
	                            btnDelete: isEditMode,
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
	                        })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(ButtonEdit, {
	                            ref: 'btnEdit',
	                            onClick: this.btnEditLapseGruppClick,
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
	                        React.createElement(Select, { title: 'All \xFCksus:',
	                            name: 'all_yksus',
	                            libs: 'lapse_all_yksus',
	                            data: all_yksused,
	                            value: self.docData.all_yksus || '',
	                            defaultValue: self.docData.all_yksys || '',
	                            ref: 'select-lapse_all_yksus',
	                            collId: 'nimetus',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
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
	                            data: nomData,
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
	                            onChange: self.handleInputChange })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(InputNumber, { ref: 'input-kogus',
	                            title: 'Kogus:',
	                            name: 'kogus',
	                            value: Number(self.docData.kogus) || 0,
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
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
	                        })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(InputDate, { title: 'Kehtib alates:',
	                            name: 'alg_kpv',
	                            value: self.docData.alg_kpv || '',
	                            ref: 'input-alg_kpv',
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(InputDate, { title: 'Kehtib kuni:',
	                            name: 'lopp_kpv',
	                            value: self.docData.lopp_kpv || '',
	                            ref: 'input-lopp_kpv',
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(CheckBox, { title: 'Kas ettemaks?',
	                            name: 'kas_ettemaks',
	                            value: Boolean(self.docData.kas_ettemaks),
	                            ref: 'checkbox_kas_ettemaks',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
	                        })
	                    ),
	                    self.docData.kas_ettemaks ? React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(InputNumber, {
	                            ref: 'input-ettemaksu_period',
	                            title: 'Ettemaksu period:',
	                            name: 'ettemaksu_period',
	                            value: Number(self.docData.ettemaksu_period) || 0,
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange
	                        })
	                    ) : null
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(CheckBox, { title: 'Kas arvesta eraldi?',
	                            name: 'kas_eraldi',
	                            value: Boolean(self.docData.kas_eraldi),
	                            ref: 'checkbox_kas_eraldi',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
	                        }),
	                        React.createElement(CheckBox, { title: 'Kas INF3?',
	                            name: 'kas_inf3',
	                            value: Boolean(self.docData.kas_inf3),
	                            ref: 'checkbox_kas_inf3',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
	                        })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docColumn },
	                        React.createElement(InputNumber, {
	                            ref: 'input-soodus',
	                            title: 'Soodustus:',
	                            name: 'soodus',
	                            value: Number(self.docData.soodus) || 0,
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange
	                        }),
	                        React.createElement(InputDate, { title: 'Kehtib alates:',
	                            name: 'sooduse_alg',
	                            value: self.docData.sooduse_alg || '',
	                            ref: 'input-soodus_alg',
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputDate, {
	                            title: 'Kehtib kuni:',
	                            name: 'sooduse_lopp',
	                            value: self.docData.sooduse_lopp || '',
	                            ref: 'input-soodus_lopp',
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange
	                        }),
	                        React.createElement(CheckBox, { title: 'Kas soodustus protsentides?',
	                            name: 'kas_protsent',
	                            value: Boolean(self.docData.kas_protsent),
	                            ref: 'checkbox_kas_protsent',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
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
	                )
	            );
	        }
	    }, {
	        key: 'handlePageClick',
	        value: function handlePageClick(pageDocTypeId) {
	            //        document.location.href = `/lapsed/${pageDocTypeId}/`;//@todo Обновить
	            this.props.history.push('/lapsed/' + pageDocTypeId);
	        }

	        //handler for input for this document type

	    }, {
	        key: 'handleInputChange',
	        value: function handleInputChange(inputName, inputValue) {

	            if (inputName === 'nomid') {
	                var Doc = this.refs['document'];

	                // надо задать цену и кол-во из того, что привязанно в группе

	                var yksus = void 0;
	                if (Doc.libs['lapse_grupp'] && Doc.docData.yksus) {
	                    yksus = Doc.libs['lapse_grupp'].find(function (obj) {
	                        return obj.kood === Doc.docData.yksus;
	                    });
	                }

	                if (yksus.teenused) {
	                    var teenus = yksus.teenused.find(function (obj) {
	                        return obj.nomid == inputValue;
	                    });

	                    Doc.docData.kogus = teenus.kogus ? teenus.kogus : Doc.docData.kogus;
	                    Doc.docData.hind = teenus.hind ? teenus.hind : Doc.docData.hind;
	                    // подменим номид на ид, так как ид виртуальный
	                    Doc.docData.nomid = teenus.nomid ? teenus.nomid : Doc.docData.nomid;

	                    // если это создание карточки, то добавим inf3
	                    var is_new = !('id' in Doc.docData) || !Doc.docData.id ? true : false;

	                    if (is_new) {
	                        var row = Doc.libs['nomenclature'].find(function (lib) {
	                            return lib.id === Number(Doc.docData.nomid);
	                        });
	                        if (row && row.kas_inf3) {
	                            Doc.docData.kas_inf3 = row.kas_inf3;
	                        }
	                    }
	                }
	            }
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
	    }, {
	        key: 'btnEditLapseGruppClick',
	        value: function btnEditLapseGruppClick() {
	            var docLapseGruppKood = this.refs['document'].docData.yksus;
	            // ищем ид

	            var lapseGruppId = this.refs['document'].libs['lapse_grupp'].find(function (row) {
	                return row.kood === docLapseGruppKood;
	            }).id;

	            if (lapseGruppId) {
	                // осуществит переход на карточку контр-агента
	                this.props.history.push('/lapsed/lapse_grupp/' + lapseGruppId);
	            }
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

/***/ 241:
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

/***/ 242:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);
	var InputNumber = __webpack_require__(214);
	var getSum = __webpack_require__(243);

	var styles = __webpack_require__(244);
	var DOC_TYPE_ID = 'LAPSE_TAABEL';

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        var _this = _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));

	        _this.state = {
	            summa: 0
	        };
	        _this.renderer = _this.renderer.bind(_this);

	        return _this;
	    }

	    _createClass(Documents, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(
	                'div',
	                null,
	                React.createElement(DocumentRegister, { initData: this.props.initData,
	                    history: this.props.history ? this.props.history : null,
	                    module: this.props.module,
	                    ref: 'register',
	                    docTypeId: DOC_TYPE_ID,
	                    style: styles,
	                    render: this.renderer }),
	                React.createElement(InputNumber, { title: 'Summa kokku:',
	                    name: 'summa_kokku',
	                    style: styles.total,
	                    ref: 'input-summa',
	                    value: Number(this.state.summa).toFixed(2) || 0,
	                    disabled: true

	                })
	            );
	        }

	        // custom render

	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            var summa = getSum(self.gridData || [], 'summa');
	            if (summa) {
	                this.setState({ summa: summa });
	            }
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

/***/ 243:
/***/ (function(module, exports) {

	"use strict";

	// will calculate sum of some field
	var getSum = function getSum(data, columnField) {

	    var total = 0;
	    if (data && data.length && data[0][columnField]) {
	        data.forEach(function (row) {
	            return total = total + Number(row[columnField]);
	        });
	    }

	    return total.toFixed(2);
	};
	module.exports = getSum;

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
	            width: '95%'
	        }

	    },
	    total: {
	        width: 'auto'
	    }
	};

/***/ }),

/***/ 245:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(32);
	var React = __webpack_require__(9);

	var DocumentTemplate = __webpack_require__(169),
	    InputNumber = __webpack_require__(214),
	    ButtonEdit = __webpack_require__(85),
	    Select = __webpack_require__(206),
	    SelectData = __webpack_require__(239),
	    TextArea = __webpack_require__(219),
	    styles = __webpack_require__(246);

	var DocContext = __webpack_require__(1);

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
	        _this.lapsIdChangehandler = _this.lapsIdChangehandler.bind(_this);

	        _this.pages = [{ pageName: 'Lapse taabel', docTypeId: 'LAPSE_TAABEL' }];
	        return _this;
	    }

	    _createClass(Laps, [{
	        key: 'componentDidMount',
	        value: function componentDidMount() {
	            if (!this.state.lapsId && DocContext['laps']) {
	                //есть значение ид ребенка
	                this.setState({ lapsId: DocContext['laps'] });
	            }
	        }
	    }, {
	        key: 'componentDidUpdate',
	        value: function componentDidUpdate(prevProps, prevState) {
	            // обновим справочники ребенка
	            if (this.state.lapsId !== prevState.lapsId) {
	                var doc = this.refs['document'];
	                doc.createLibs();
	            }
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var filter = this.state.lapsId ? 'where lapsid = ' + this.state.lapsId : '';

	            var LIBRARIES = [{ id: 'lapse_kaart', filter: filter }];

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
	            var isEditMode = self.state.edited;

	            if ((self.docData.id === 0 || !self.docData.parentid) && this.state.lapsId) {
	                //new record
	                self.docData.parentid = this.state.lapsId;
	            }

	            if (!this.state.lapsId && self.docData.parentid) {
	                this.setState({ lapsId: self.docData.parentid });
	            }

	            var kpv = new Date(),
	                kuu = kpv.getMonth(),
	                aasta = kpv.getFullYear();

	            var buttonEditNom = styles.btnEditNom;

	            //фильтр на используемы номенклатуры
	            var nomData = self.libs['lapse_kaart'] ? self.libs['lapse_kaart'].filter(function (row) {
	                return row.lapsid === self.docData.parentid;
	            }) : [];

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
	                            onChange: this.lapsIdChangehandler,
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
	                            name: 'lapse_kaart_id',
	                            libs: 'lapse_kaart',
	                            data: nomData,
	                            value: self.docData.lapse_kaart_id || 0,
	                            defaultValue: self.docData.nimetus,
	                            ref: 'select-lapse_kaart_id',
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
	            var docId = this.refs['document'].docData.lapse_kaart_id;

	            // осуществит переход на карточку контр-агента
	            this.props.history.push('/lapsed/lapse_kaart/' + docId);
	        }

	        //обработчик события по клику кнопки Редактирование ребенка

	    }, {
	        key: 'btnEditLapsClick',
	        value: function btnEditLapsClick() {
	            var docLapsId = this.refs['document'].docData.parentid;

	            // осуществит переход на карточку контр-агента
	            this.props.history.push('/lapsed/laps/' + docLapsId);
	        }
	    }, {
	        key: 'lapsIdChangehandler',
	        value: function lapsIdChangehandler(inputName, inputValue) {
	            var Doc = this.refs['document'];

	            // отдать значение документу
	            Doc.handleInputChange(inputName, inputValue);

	            // обновить справочник
	            Doc.createLibs();
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

/***/ 246:
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

/***/ 247:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(32);
	var React = __webpack_require__(9);

	var DocumentTemplate = __webpack_require__(169),
	    InputText = __webpack_require__(212),
	    Select = __webpack_require__(206),
	    ButtonEdit = __webpack_require__(85),
	    SelectData = __webpack_require__(239),
	    TextArea = __webpack_require__(219),
	    DataGrid = __webpack_require__(184),
	    CheckBox = __webpack_require__(237),
	    styles = __webpack_require__(248);

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
	                            readOnly: !isEditMode }),
	                        self.docData.arved === 'Jah' ? React.createElement(CheckBox, { title: 'Print paberil ?',
	                            name: 'kas_paberil',
	                            value: Boolean(self.docData.kas_paberil),
	                            ref: 'checkbox_kas_paberil',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
	                        }) : null,
	                        self.docData.arved === 'Jah' ? React.createElement(CheckBox, { title: 'E-arve ?',
	                            name: 'kas_earve',
	                            value: Boolean(self.docData.kas_earve),
	                            ref: 'checkbox_kas_earve',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
	                        }) : null,
	                        self.docData.arved === 'Jah' ? React.createElement(CheckBox, { title: 'Kas email ?',
	                            name: 'kas_email',
	                            value: Boolean(self.docData.kas_email),
	                            ref: 'checkbox_kas_email',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditMode
	                        }) : null
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

/***/ 248:
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

/***/ 249:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);
	var styles = __webpack_require__(250);
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

/***/ 250:
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

/***/ 282:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);
	var styles = __webpack_require__(283);
	var DOC_TYPE_ID = 'LAPSE_GRUPP';

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
	                'Lapse grupp register special render'
	            );
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 283:
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

/***/ 284:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(32);
	var React = __webpack_require__(9);

	var DocumentTemplate = __webpack_require__(169),
	    InputText = __webpack_require__(212),
	    Select = __webpack_require__(206),
	    InputNumber = __webpack_require__(214),
	    TextArea = __webpack_require__(219),
	    DataGrid = __webpack_require__(184),
	    ModalPage = __webpack_require__(180),
	    styles = __webpack_require__(285);

	var LIBRARIES = [{ id: 'nomenclature', filter: 'where dok = \'ARV\'' }];

	var LapseGrupp = function (_React$PureComponent) {
	    _inherits(LapseGrupp, _React$PureComponent);

	    function LapseGrupp(props) {
	        _classCallCheck(this, LapseGrupp);

	        var _this = _possibleConstructorReturn(this, (LapseGrupp.__proto__ || Object.getPrototypeOf(LapseGrupp)).call(this, props));

	        _this.state = {
	            loadedData: false,
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            module: 'lapsed'
	        };

	        _this.renderer = _this.renderer.bind(_this);
	        _this.createGridRow = _this.createGridRow.bind(_this);
	        _this.gridValidateFields = _this.gridValidateFields.bind(_this);

	        //        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
	        return _this;
	    }

	    _createClass(LapseGrupp, [{
	        key: 'render',
	        value: function render() {
	            var initData = this.props.initData ? this.props.initData : {};

	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                module: this.state.module,
	                docTypeId: 'LAPSE_GRUPP',
	                libs: LIBRARIES,
	                userData: this.props.userData,
	                initData: initData,
	                renderer: this.renderer,
	                createGridRow: this.createGridRow,
	                gridValidator: this.gridValidateFields,
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
	            var isEditMode = self.state.edited;

	            if ((self.docData.id === 0 || !self.docData.parentid) && this.state.lapsId) {
	                //new record
	                self.docData.parentid = this.state.lapsId;
	            }

	            var gridValue = void 0;
	            if (self.gridRowData) {
	                gridValue = self.gridRowData.id ? self.gridRowData.id : null;
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
	                        React.createElement(InputText, { title: 'Kood:',
	                            name: 'kood',
	                            value: self.docData.kood || '',
	                            ref: 'input-kood',
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputText, { title: 'Nimetus:',
	                            name: 'nimetus',
	                            value: self.docData.nimetus || '',
	                            ref: 'input-nimetus',
	                            readOnly: !isEditMode,
	                            onChange: self.handleInputChange }),
	                        React.createElement(
	                            'label',
	                            null,
	                            'All \xFCksused',
	                            React.createElement(InputText, { title: '',
	                                name: 'all_yksus_1',
	                                value: self.docData.all_yksus_1 || '',
	                                ref: 'input-all_yksus_1',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange }),
	                            React.createElement(InputText, { title: '',
	                                name: 'all_yksus_2',
	                                value: self.docData.all_yksus_2 || '',
	                                ref: 'input-all_yksus_2',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange }),
	                            React.createElement(InputText, { title: '',
	                                name: 'all_yksus_3',
	                                value: self.docData.all_yksus_3 || '',
	                                ref: 'input-all_yksus_3',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange }),
	                            React.createElement(InputText, { title: '',
	                                name: 'all_yksus_4',
	                                value: self.docData.all_yksus_4 || '',
	                                ref: 'input-all_yksus_4',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange }),
	                            React.createElement(InputText, { title: '',
	                                name: 'all_yksus_5',
	                                value: self.docData.all_yksus_5 || '',
	                                ref: 'input-all_yksus_5',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange })
	                        )
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(DataGrid, { source: 'teenused',
	                        gridData: self.docData.gridData,
	                        gridColumns: self.docData.gridConfig,
	                        showToolBar: isEditMode,
	                        createGridRow: this.createGridRow,
	                        handleGridRow: self.handleGridRow,
	                        handleGridBtnClick: self.handleGridBtnClick,
	                        readOnly: !isEditMode,
	                        style: styles.grid.headerTable,
	                        ref: 'data-grid' })
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
	                self.state.gridRowEdit ? this.createGridRow(self) : null
	            );
	        }

	        /**
	         * формирует объекты модального окна редактирования строки грида
	         * @returns {XML}
	         */

	    }, {
	        key: 'createGridRow',
	        value: function createGridRow(self) {
	            var row = self.gridRowData ? self.gridRowData : {},
	                validateMessage = '',
	                // self.state.warning
	            buttonOkReadOnly = validateMessage.length > 0 || !self.state.checked,
	                modalObjects = ['btnOk', 'btnCancel'];

	            if (buttonOkReadOnly) {
	                // уберем кнопку Ок
	                modalObjects.splice(0, 1);
	            }

	            if (!row) return React.createElement('div', null);

	            return React.createElement(
	                'div',
	                { className: '.modalPage' },
	                React.createElement(
	                    ModalPage,
	                    {
	                        modalObjects: modalObjects,
	                        ref: 'modalpage-grid-row',
	                        show: true,
	                        modalPageBtnClick: self.modalPageClick,
	                        modalPageName: 'Rea lisamine / parandamine' },
	                    React.createElement(
	                        'div',
	                        { ref: 'grid-row-container' },
	                        self.state.gridWarning.length ? React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(
	                                'span',
	                                null,
	                                self.state.gridWarning
	                            )
	                        ) : null,
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(Select, { title: 'Teenus',
	                                name: 'nomid',
	                                libs: 'nomenclature',
	                                data: self.libs['nomenclature'],
	                                value: Number(row.nomid) || 0,
	                                defaultValue: row.kood || '',
	                                ref: 'nomid',
	                                collId: 'id',
	                                placeholder: 'Teenuse kood',
	                                onChange: self.handleGridRowChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Kogus: ',
	                                name: 'kogus',
	                                value: Number(row.kogus) || 1,
	                                bindData: false,
	                                ref: 'kogus',
	                                onChange: self.handleGridRowInput })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Hind: ',
	                                name: 'hind',
	                                value: Number(row.hind) || 0,
	                                bindData: false,
	                                ref: 'hind',
	                                onChange: self.handleGridRowInput })
	                        )
	                    ),
	                    React.createElement(
	                        'div',
	                        null,
	                        React.createElement(
	                            'span',
	                            null,
	                            validateMessage
	                        )
	                    )
	                )
	            );
	        }

	        /**
	         * валидатор для строки грида
	         * @returns {string}
	         */

	    }, {
	        key: 'gridValidateFields',
	        value: function gridValidateFields() {
	            var warning = '';
	            var doc = this.refs['document'];
	            if (doc && doc.gridRowData) {

	                // только после проверки формы на валидность
	                if (doc.gridRowData && !doc.gridRowData['nomid']) warning = warning + ' Puudub operatsioon';

	                //подставим наименование услогу

	                if (doc.gridRowData['nomid']) {

	                    var nomDataName = doc.libs['nomenclature'].find(function (lib) {
	                        return Number(lib.id) === Number(doc.gridRowData['nomid']);
	                    });

	                    doc.gridRowData['kood'] = nomDataName.kood;
	                    doc.gridRowData['nimetus'] = nomDataName.nimetus;

	                    if (!doc.gridRowData['hind']) {
	                        doc.gridRowData['hind'] = nomDataName.hind;
	                    }
	                }

	                if (!doc.gridRowData['kogus']) {
	                    doc.gridRowData['kogus'] = 1;
	                }
	            }
	            return warning;
	        }
	    }]);

	    return LapseGrupp;
	}(React.PureComponent);

	LapseGrupp.propTypes = {
	    docId: PropTypes.number,
	    initData: PropTypes.object,
	    userData: PropTypes.object
	};

	LapseGrupp.defaultProps = {
	    params: { docId: 0 },
	    initData: {},
	    userData: {}
	};

	module.exports = LapseGrupp;

/***/ }),

/***/ 285:
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

/***/ 286:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);

	var styles = __webpack_require__(287);
	var DOC_TYPE_ID = 'PANK_VV';
	var toolbarParams = {
	    btnAdd: {
	        show: false
	    },
	    btnEdit: {
	        show: true
	    },
	    btnDelete: {
	        show: true
	    },
	    btnPrint: {
	        show: false
	    },
	    btnStart: {
	        show: false
	    }
	};

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        var _this = _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));

	        _this.btnEditClick = _this.btnEditClick.bind(_this);
	        _this.Doc = null; //ссылка на страницу
	        _this.renderer = _this.renderer.bind(_this);
	        _this.render = _this.render.bind(_this);
	        return _this;
	    }

	    _createClass(Documents, [{
	        key: 'render',
	        value: function render() {
	            var state = this.Doc && this.Doc.state ? this.Doc.state : null;
	            if (this.Doc) {
	                toolbarParams['btnEdit'].show = state.value ? true : false;
	            }

	            return React.createElement(DocumentRegister, { initData: this.props.initData,
	                history: this.props.history ? this.props.history : null,
	                module: this.props.module,
	                ref: 'register',
	                docTypeId: DOC_TYPE_ID,
	                style: styles,
	                toolbarParams: toolbarParams,
	                btnEditClick: this.btnEditClick,
	                render: this.renderer });
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            this.Doc = self;
	        }
	    }, {
	        key: 'btnEditClick',
	        value: function btnEditClick() {
	            // кастомный обработчик события
	            if (this.Doc && this.Doc.state) {
	                var value = this.Doc.state.value;
	                var gridData = this.Doc.gridData;
	                var doc_id = gridData.find(function (row) {
	                    return row.id = value;
	                }).doc_id;
	                if (doc_id) {
	                    return this.props.history.push({
	                        pathname: '/' + this.props.module + '/SMK/' + doc_id,
	                        state: { module: this.props.module }
	                    });
	                } else {
	                    this.Doc.setState({
	                        warning: 'Maksekorraldus ei leidnud',
	                        warningType: 'error'
	                    });
	                }
	            }
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 287:
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

/***/ 288:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var PropTypes = __webpack_require__(32);

	var DocumentTemplate = __webpack_require__(169),
	    InputText = __webpack_require__(212),
	    TextArea = __webpack_require__(219),
	    styles = __webpack_require__(289);

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Config = function (_React$PureComponent) {
	    _inherits(Config, _React$PureComponent);

	    function Config(props) {
	        _classCallCheck(this, Config);

	        var _this = _possibleConstructorReturn(this, (Config.__proto__ || Object.getPrototypeOf(Config)).call(this, props));

	        _this.state = {
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            loadedData: false
	        };
	        _this.renderer = _this.renderer.bind(_this);
	        return _this;
	    }

	    _createClass(Config, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'CONFIG',
	                history: this.props.history,
	                module: this.props.module,
	                initData: this.props.initData,
	                renderer: this.renderer
	            });
	        }

	        /**
	         * Метод вернет кастомный компонент
	         * @param self
	         * @returns {*}
	         */

	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            if (!self.docData) {
	                return null;
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
	                        React.createElement(InputText, { title: 'Prefiks: ',
	                            name: 'number',
	                            ref: 'input-number',
	                            readOnly: !self.state.edited,
	                            value: self.docData.number || '',
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputText, { title: 'Arvete tahtp\xE4ev ',
	                            name: 'tahtpaev',
	                            ref: 'input-tahtpaev',
	                            readOnly: !self.state.edited,
	                            value: self.docData.tahtpaev || '',
	                            onChange: self.handleInputChange })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(TextArea, { title: 'Omniva e-arvete server',
	                        name: 'earved',
	                        ref: 'textarea-earved',
	                        onChange: self.handleInputChange,
	                        value: self.docData.earved || '',
	                        readOnly: !self.state.edited })
	                )
	            );
	        }
	    }]);

	    return Config;
	}(React.PureComponent);

	Config.propTypes = {
	    docId: PropTypes.number,
	    initData: PropTypes.object
	};

	Config.defaultProps = {
	    initData: {}
	};

	module.exports = Config;

/***/ }),

/***/ 289:
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
	    }
	};

/***/ }),

/***/ 290:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var PropTypes = __webpack_require__(32);

	var DocumentTemplate = __webpack_require__(169),
	    InputText = __webpack_require__(212),
	    DataGrid = __webpack_require__(184),
	    TextArea = __webpack_require__(219),
	    ModalPage = __webpack_require__(180),
	    Select = __webpack_require__(206),
	    CheckBox = __webpack_require__(237),
	    styles = __webpack_require__(291);

	var LIB_OBJS = [{ id: 'kontod', filter: '' }];

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Rekv = function (_React$PureComponent) {
	    _inherits(Rekv, _React$PureComponent);

	    function Rekv(props) {
	        _classCallCheck(this, Rekv);

	        var _this = _possibleConstructorReturn(this, (Rekv.__proto__ || Object.getPrototypeOf(Rekv)).call(this, props));

	        _this.state = {
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            loadedData: false
	        };
	        _this.renderer = _this.renderer.bind(_this);
	        _this.createGridRow = _this.createGridRow.bind(_this);
	        return _this;
	    }

	    _createClass(Rekv, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'REKV',
	                history: this.props.history,
	                module: this.props.module,
	                libs: LIB_OBJS,
	                initData: this.props.initData,
	                renderer: this.renderer,
	                createGridRow: this.createGridRow

	            });
	        }

	        /**
	         * Метод вернет кастомный компонент
	         * @param self
	         * @returns {*}
	         */

	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            if (!self.docData) {
	                return null;
	            }
	            var gridData = self.docData.gridData,
	                gridColumns = self.docData.gridConfig;

	            return React.createElement(
	                'div',
	                { style: styles.doc },
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputText, { title: 'Regkood: ',
	                        name: 'regkood',
	                        ref: 'input-regkood',
	                        readOnly: !self.state.edited,
	                        value: self.docData.regkood || '',
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputText, { title: 'KBM kood: ',
	                        name: 'kbmkood',
	                        ref: 'input-kbmkood',
	                        readOnly: !self.state.edited,
	                        value: self.docData.kbmkood || '',
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputText, {
	                        title: 'Nimetus: ',
	                        name: 'nimetus',
	                        ref: 'input-nimetus',
	                        readOnly: !self.state.edited,
	                        value: self.docData.nimetus || '',
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputText, { title: 'T\xE4is. nimetus: ',
	                        name: 'muud',
	                        ref: 'input-muud',
	                        readOnly: !self.state.edited,
	                        value: self.docData.muud || '',
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(TextArea, { title: 'Aadress: ',
	                        name: 'aadress',
	                        ref: 'textarea-aadress',
	                        onChange: self.handleInputChange,
	                        value: self.docData.aadress || '',
	                        readOnly: !self.state.edited })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputText, { title: 'Juhataja: ',
	                        name: 'juht',
	                        ref: 'input-juht',
	                        readOnly: !self.state.edited,
	                        value: self.docData.juht || '',
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputText, { title: 'Raamatupidaja: ',
	                        name: 'raama',
	                        ref: 'input-raama',
	                        readOnly: !self.state.edited,
	                        value: self.docData.raama || '',
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputText, { title: 'Email: ',
	                        name: 'email',
	                        ref: 'input-email',
	                        readOnly: !self.state.edited,
	                        value: self.docData.email || '',
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputText, { title: 'Omniva salas\xF5na: ',
	                        name: 'earved',
	                        ref: 'input-earved',
	                        readOnly: !self.state.edited,
	                        value: self.docData.earved || '',
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(DataGrid, { source: 'details',
	                        gridData: gridData,
	                        gridColumns: gridColumns,
	                        showToolBar: self.state.edited,
	                        handleGridRow: this.handleGridRow,
	                        handleGridBtnClick: self.handleGridBtnClick,
	                        readOnly: !self.state.edited,
	                        style: styles.grid.headerTable,
	                        ref: 'data-grid' })
	                ),
	                self.state.gridRowEdit ? this.createGridRow(self) : null
	            );
	        }

	        /**
	         * Создаст компонет строки грида
	         * @returns {XML}
	         */

	    }, {
	        key: 'createGridRow',
	        value: function createGridRow(self) {

	            var row = self.gridRowData ? self.gridRowData : {},
	                validateMessage = '',
	                // self.state.warning
	            buttonOkReadOnly = validateMessage.length > 0 || !self.state.checked,
	                modalObjects = ['btnOk', 'btnCancel'];

	            if (buttonOkReadOnly) {
	                // уберем кнопку Ок
	                modalObjects.splice(0, 1);
	            }

	            if (!row) return React.createElement('div', null);

	            return React.createElement(
	                'div',
	                { className: '.modalPage' },
	                React.createElement(
	                    ModalPage,
	                    {
	                        modalObjects: modalObjects,
	                        ref: 'modalpage-grid-row',
	                        show: true,
	                        modalPageBtnClick: self.modalPageClick,
	                        modalPageName: 'Rea lisamine / parandamine' },
	                    React.createElement(
	                        'div',
	                        { ref: 'grid-row-container' },
	                        self.state.gridWarning.length ? React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(
	                                'span',
	                                null,
	                                self.state.gridWarning
	                            )
	                        ) : null,
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputText, { title: 'Number: ',
	                                name: 'arve',
	                                value: row.arve || '',
	                                readOnly: false,
	                                disabled: false,
	                                bindData: false,
	                                ref: 'number',
	                                onChange: self.handleGridRowInput })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputText, { title: 'Nimetus: ',
	                                name: 'nimetus',
	                                value: row.nimetus || '',
	                                readOnly: false,
	                                disabled: false,
	                                bindData: false,
	                                ref: 'number',
	                                onChange: self.handleGridRowInput })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(Select, { title: 'T\xFC\xFCp: ',
	                                name: 'kassapank',
	                                data: [{ id: 0, nimetus: 'Kassa' }, { id: 1, nimetus: 'Pank' }, { id: 2, nimetus: 'TP' }],
	                                value: row.kassapank || '',
	                                ref: 'kassapank',
	                                collId: 'id',
	                                onChange: self.handleGridRowChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(Select, { title: 'Konto: ',
	                                name: 'konto',
	                                data: self.libs['kontod'],
	                                value: row.konto || '',
	                                ref: 'konto',
	                                collId: 'kood',
	                                onChange: self.handleGridRowChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(CheckBox, { title: 'Kas p\xF5hiline?',
	                                name: 'default_',
	                                value: Boolean(self.docData.default_),
	                                ref: 'checkbox_default_',
	                                onChange: self.handleInputChange,
	                                readOnly: false
	                            })
	                        )
	                    ),
	                    React.createElement(
	                        'div',
	                        null,
	                        React.createElement(
	                            'span',
	                            null,
	                            validateMessage
	                        )
	                    )
	                )
	            );
	        }
	    }]);

	    return Rekv;
	}(React.PureComponent);

	Rekv.propTypes = {
	    docId: PropTypes.number,
	    initData: PropTypes.object
	};

	Rekv.defaultProps = {
	    initData: {}
	};

	module.exports = Rekv;

/***/ }),

/***/ 291:
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

/***/ 292:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var PropTypes = __webpack_require__(32);

	var DocumentTemplate = __webpack_require__(169),
	    InputText = __webpack_require__(212),
	    TextArea = __webpack_require__(219),
	    Select = __webpack_require__(206),
	    styles = __webpack_require__(293);
	var LIBRARIES = [{ id: 'kontod', filter: 'where len(kood::text) >= 6' }];

	var Project = function (_React$PureComponent) {
	    _inherits(Project, _React$PureComponent);

	    function Project(props) {
	        _classCallCheck(this, Project);

	        var _this = _possibleConstructorReturn(this, (Project.__proto__ || Object.getPrototypeOf(Project)).call(this, props));

	        _this.state = {
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            loadedData: false,
	            docTypeId: _this.props.history.location.state ? _this.props.history.location.state.docPropId : ''
	        };
	        _this.renderer = _this.renderer.bind(_this);

	        return _this;
	    }

	    _createClass(Project, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                history: this.props.history,
	                libs: LIBRARIES,
	                docTypeId: 'DOKPROPS',
	                initData: this.props.initData,
	                renderer: this.renderer });
	        }

	        /**
	         * Метод вернет кастомный компонент
	         * @param self
	         * @returns {*}
	         */

	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            if (!self.docData) {
	                return null;
	            }
	            if (!self.docData.dok && this.props.history) {
	                self.docData.dok = this.props.history.location.state.dokPropId;
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
	                        React.createElement(InputText, { title: 'Dokument ',
	                            name: 'dok',
	                            ref: 'input-dok',
	                            readOnly: true,
	                            value: self.docData.dok
	                        }),
	                        React.createElement(Select, { title: 'Korr. konto: ',
	                            name: 'konto',
	                            libs: 'kontod',
	                            data: self.libs['kontod'],
	                            value: self.docData.konto,
	                            readOnly: !self.state.edited,
	                            ref: 'konto',
	                            collId: 'kood',
	                            onChange: self.handleInputChange }),
	                        React.createElement(Select, { title: 'KBM.konto: ',
	                            name: 'kbmkonto',
	                            libs: 'kontod',
	                            data: self.libs['kontod'],
	                            value: self.docData.kbmkonto,
	                            readOnly: !self.state.edited,
	                            ref: 'kbmkonto',
	                            collId: 'kood',
	                            onChange: self.handleInputChange })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(TextArea, { title: 'Selgitus',
	                        name: 'selg',
	                        ref: 'textarea-selg',
	                        onChange: self.handleInputChange,
	                        value: self.docData.selg || '',
	                        readOnly: !self.state.edited })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(TextArea, { title: 'Muud',
	                        name: 'muud',
	                        ref: 'textarea-muud',
	                        onChange: self.handleInputChange,
	                        value: self.docData.muud || '',
	                        readOnly: !self.state.edited })
	                )
	            );
	        }
	    }]);

	    return Project;
	}(React.PureComponent);

	Project.propTypes = {
	    docId: PropTypes.number,
	    initData: PropTypes.object,
	    userData: PropTypes.object
	};

	Project.defaultProps = {
	    initData: {},
	    userData: {}
	};
	module.exports = Project;

/***/ }),

/***/ 293:
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
	    }
	};

/***/ }),

/***/ 294:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var PropTypes = __webpack_require__(32);

	var DocumentTemplate = __webpack_require__(169),
	    InputText = __webpack_require__(212),
	    TextArea = __webpack_require__(219),
	    styles = __webpack_require__(295);

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var User = function (_React$PureComponent) {
	    _inherits(User, _React$PureComponent);

	    function User(props) {
	        _classCallCheck(this, User);

	        var _this = _possibleConstructorReturn(this, (User.__proto__ || Object.getPrototypeOf(User)).call(this, props));

	        _this.state = {
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            loadedData: false
	        };
	        _this.renderer = _this.renderer.bind(_this);
	        return _this;
	    }

	    _createClass(User, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'USERID',
	                module: this.props.module,
	                initData: this.props.initData,
	                renderer: this.renderer
	            });
	        }

	        /**
	         * Метод вернет кастомный компонент
	         * @param self
	         * @returns {*}
	         */

	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            if (!self.docData) {
	                return null;
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
	                        React.createElement(InputText, { title: 'Kasutaja tunnus:  ',
	                            name: 'kasutaja',
	                            ref: 'input-kasutaja',
	                            readOnly: true,
	                            value: self.docData.kasutaja || '',
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputText, { title: 'Nimi: ',
	                            name: 'ametnik',
	                            ref: 'input-ametnik',
	                            readOnly: !self.state.edited,
	                            value: self.docData.ametnik || '',
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputText, { title: 'Email: ',
	                            name: 'email',
	                            ref: 'input-email',
	                            readOnly: !self.state.edited,
	                            value: self.docData.email || '',
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputText, { title: 'Smtp: ',
	                            name: 'smtp',
	                            ref: 'input-smtp',
	                            readOnly: !self.state.edited,
	                            value: self.docData.smtp || '',
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputText, { title: 'Port: ',
	                            name: 'port',
	                            ref: 'input-port',
	                            readOnly: !self.state.edited,
	                            value: self.docData.port || '',
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputText, { title: 'Email kasutaja: ',
	                            name: 'user',
	                            ref: 'input-user',
	                            readOnly: !self.state.edited,
	                            value: self.docData.user || '',
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputText, { title: 'Email parool: ',
	                            name: 'pass',
	                            ref: 'input-pass',
	                            readOnly: !self.state.edited,
	                            value: self.docData.pass || '',
	                            onChange: self.handleInputChange })
	                    )
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(TextArea, { title: 'Muud',
	                        name: 'muud',
	                        ref: 'textarea-muud',
	                        onChange: self.handleInputChange,
	                        value: self.docData.muud || '',
	                        readOnly: !self.state.edited })
	                )
	            );
	        }
	    }]);

	    return User;
	}(React.PureComponent);

	User.propTypes = {
	    docId: PropTypes.number,
	    initData: PropTypes.object
	};

	User.defaultProps = {
	    initData: {}
	};

	module.exports = User;

/***/ }),

/***/ 295:
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
	    }
	};

/***/ }),

/***/ 296:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);
	var BtnGetXml = __webpack_require__(232);
	var ToolbarContainer = __webpack_require__(79);

	var styles = __webpack_require__(297);
	var DOC_TYPE_ID = 'INF3';
	var DocContext = __webpack_require__(1);

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        var _this = _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));

	        _this.onClickHandler = _this.onClickHandler.bind(_this);
	        _this.renderer = _this.renderer.bind(_this);
	        return _this;
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
	        value: function renderer(self) {
	            return React.createElement(
	                ToolbarContainer,
	                null,
	                React.createElement(BtnGetXml, {
	                    value: 'Saama XML fail',
	                    onClick: this.onClickHandler,
	                    ref: 'btn-getXml'
	                })
	            );
	        }

	        //handler для события клик на кнопках панели

	    }, {
	        key: 'onClickHandler',
	        value: function onClickHandler(event) {
	            var Doc = this.refs['register'];

	            if (Doc.gridData && Doc.gridData.length) {
	                //делаем редайрект на конфигурацию
	                var sqlWhere = Doc.state.sqlWhere;
	                var url = '/reports/inf3/' + DocContext.userData.uuid;
	                var params = encodeURIComponent('' + sqlWhere);
	                window.open(url + '/' + params);
	            } else {
	                Doc.setState({
	                    warning: 'Mitte ühtegi INF teenused leidnum', // строка извещений
	                    warningType: 'notValid'

	                });
	            }
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 297:
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

/***/ 298:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);
	var InputNumber = __webpack_require__(214);
	var getSum = __webpack_require__(243);

	var styles = __webpack_require__(299);
	var DOC_TYPE_ID = 'LAPS_KOKKUVOTTE';

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        var _this = _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));

	        _this.state = {
	            summa: 0,
	            tasutud: 0,
	            jaak: 0
	        };

	        _this.renderer = _this.renderer.bind(_this);
	        return _this;
	    }

	    _createClass(Documents, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(
	                'div',
	                null,
	                React.createElement(DocumentRegister, { initData: this.props.initData,
	                    history: this.props.history ? this.props.history : null,
	                    module: this.props.module,
	                    ref: 'register',
	                    docTypeId: DOC_TYPE_ID,
	                    style: styles,
	                    render: this.renderer }),
	                ';',
	                React.createElement(InputNumber, { title: 'Arve summa kokku:',
	                    name: 'summa_kokku',
	                    style: styles.total,
	                    ref: 'input-summa',
	                    value: Number(this.state.summa).toFixed(2) || 0,
	                    disabled: true }),
	                React.createElement(InputNumber, { title: 'J\xE4\xE4k kokku:',
	                    name: 'jaak_kokku',
	                    style: styles.total,
	                    ref: 'input-jaak',
	                    value: Number(this.state.jaak).toFixed(2) || 0,
	                    disabled: true }),
	                React.createElement(InputNumber, { title: 'Tasutud kokku:',
	                    name: 'tasutud_kokku',
	                    style: styles.total,
	                    ref: 'input-tasutud',
	                    value: Number(this.state.tasutud).toFixed(2) || 0,
	                    disabled: true })
	            );
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            var summa = self.gridData ? getSum(self.gridData, 'summa') : 0;
	            var tasutud = self.gridData ? getSum(self.gridData, 'tasutud') : 0;
	            var jaak = self.gridData ? getSum(self.gridData, 'jaak') : 0;
	            if (summa) {
	                this.setState({ summa: summa, tasutud: tasutud, jaak: jaak });
	            }

	            return React.createElement('div', null);
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 299:
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

	    },
	    total: {
	        width: 'auto'
	    }

	};

/***/ }),

/***/ 300:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);
	var BtnGetCsv = __webpack_require__(232);
	var ToolbarContainer = __webpack_require__(79);
	var InputNumber = __webpack_require__(214);
	var getSum = __webpack_require__(243);

	var DocContext = __webpack_require__(1);

	var styles = __webpack_require__(301);
	var DOC_TYPE_ID = 'ARVED_KOODI_JARGI';

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        var _this = _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));

	        _this.state = {
	            summa: 0
	        };
	        _this.renderer = _this.renderer.bind(_this);
	        _this.onClickHandler = _this.onClickHandler.bind(_this);

	        return _this;
	    }

	    _createClass(Documents, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(
	                'div',
	                null,
	                React.createElement(DocumentRegister, { initData: this.props.initData,
	                    history: this.props.history ? this.props.history : null,
	                    module: this.props.module,
	                    ref: 'register',
	                    docTypeId: DOC_TYPE_ID,
	                    style: styles,
	                    render: this.renderer }),
	                ';',
	                React.createElement(InputNumber, { title: 'Summa kokku:',
	                    name: 'summa_kokku',
	                    style: styles.total,
	                    ref: 'input-summa',
	                    value: Number(this.state.summa).toFixed(2) || 0,
	                    disabled: true })
	            );
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            var summa = self.gridData ? getSum(self.gridData, 'summa') : 0;
	            if (summa) {
	                this.setState({ summa: summa });
	            }

	            return React.createElement(
	                ToolbarContainer,
	                null,
	                React.createElement(BtnGetCsv, {
	                    value: 'Saama CSV fail',
	                    onClick: this.onClickHandler,
	                    showDate: false,
	                    ref: 'btn-getcsv'
	                })
	            );
	        }

	        //handler для события клик на кнопках панели

	    }, {
	        key: 'onClickHandler',
	        value: function onClickHandler(event) {
	            var Doc = this.refs['register'];

	            if (Doc.gridData && Doc.gridData.length) {
	                //делаем редайрект на конфигурацию
	                var sqlWhere = Doc.state.sqlWhere;
	                var url = '/reports/arved_koodi_jargi/' + DocContext.userData.uuid;
	                var params = encodeURIComponent('' + sqlWhere);
	                window.open(url + '/' + params);
	            } else {
	                Doc.setState({
	                    warning: 'Mitte ühtegi kirjed leidnud', // строка извещений
	                    warningType: 'notValid'

	                });
	            }
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 301:
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
	            width: '95%'
	        }

	    },
	    total: {
	        width: 'auto'
	    }

	};

/***/ }),

/***/ 302:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);
	var BtnGetXml = __webpack_require__(232);
	var ToolbarContainer = __webpack_require__(79);

	var styles = __webpack_require__(303);
	var DOC_TYPE_ID = 'SALDO_JA_KAIVE';
	var DocContext = __webpack_require__(1);

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        var _this = _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));

	        _this.onClickHandler = _this.onClickHandler.bind(_this);
	        _this.renderer = _this.renderer.bind(_this);
	        return _this;
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
	                ToolbarContainer,
	                null,
	                React.createElement(BtnGetXml, {
	                    value: 'Saama XML fail',
	                    onClick: this.onClickHandler,
	                    showDate: false,
	                    ref: 'btn-getXml'
	                })
	            );
	        }

	        //handler для события клик на кнопках панели

	    }, {
	        key: 'onClickHandler',
	        value: function onClickHandler() {
	            var Doc = this.refs['register'];

	            if (Doc.gridData && Doc.gridData.length) {
	                //делаем редайрект на конфигурацию
	                var sqlWhere = Doc.state.sqlWhere;
	                var url = '/reports/saldo_ja_kaive/' + DocContext.userData.uuid;
	                var params = encodeURIComponent('' + sqlWhere);
	                var filter = encodeURIComponent('' + JSON.stringify(Doc.filterData));
	                window.open(url + '/' + params + '/' + filter);
	            } else {
	                Doc.setState({
	                    warning: 'Mitte ühtegi kirjed leidnud', // строка извещений
	                    warningType: 'notValid'

	                });
	            }
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 303:
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

/***/ 327:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(9);
	var DocumentRegister = __webpack_require__(226);
	var styles = __webpack_require__(328);
	var DOC_TYPE_ID = 'SENT_DOCS';

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Documents = function (_React$PureComponent) {
	    _inherits(Documents, _React$PureComponent);

	    function Documents(props) {
	        _classCallCheck(this, Documents);

	        var _this = _possibleConstructorReturn(this, (Documents.__proto__ || Object.getPrototypeOf(Documents)).call(this, props));

	        _this.renderer = _this.renderer.bind(_this);
	        return _this;
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
	                'Saadetud dokumemndid'
	            );
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 328:
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
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibGFwc2VkLmpzIiwic291cmNlcyI6WyJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvbGFwc2VkLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL21vZHVsZXMvbGFwc2VkLmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHMvZG9jdW1lbnQvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwcy9kb2N1bWVudC9sYXBzLnN0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHMvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi10YXNrL2luZGV4LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHMvbGFwcy1yZWdpc3Rlci1zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9sYXBzZV9rYWFydC9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9sYXBzZV9rYWFydC9zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9sYXBzZV9rYWFydC9kb2N1bWVudC9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9sYXBzZV9rYWFydC9kb2N1bWVudC9zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9sYXBzZV90YWFiZWwvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2xpYnMvZ2V0U3VtLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwc2VfdGFhYmVsL3N0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2xhcHNlX3RhYWJlbC9kb2N1bWVudC9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9sYXBzZV90YWFiZWwvZG9jdW1lbnQvc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvdmFuZW0vZG9jdW1lbnQvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvdmFuZW0vZG9jdW1lbnQvc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvdmFuZW0vaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvdmFuZW0vc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwc2VfZ3J1cHAvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwc2VfZ3J1cHAvc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwc2VfZ3J1cHAvZG9jdW1lbnQvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvbGFwc2VfZ3J1cHAvZG9jdW1lbnQvc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvcGFua192di9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9wYW5rX3Z2L3N0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2NvbmZpZy9kb2N1bWVudC9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9jb25maWcvZG9jdW1lbnQvc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvcmVrdi9kb2N1bWVudC9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9yZWt2L2RvY3VtZW50L3N0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2Rva3Byb3BzL2RvY3VtZW50L2luZGV4LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2Rva3Byb3BzL2RvY3VtZW50L3N0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3VzZXJpZC9kb2N1bWVudC9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy91c2VyaWQvZG9jdW1lbnQvc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvaW5mMy9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9pbmYzL3N0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2NoaWxkX3N1bW1hcnkvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvY2hpbGRfc3VtbWFyeS9zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9hcnZlZF9rb29kaV9qYXJnaS9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9hcnZlZF9rb29kaV9qYXJnaS9zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9zYWxkb19qYV9rYWl2ZS9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9zYWxkb19qYV9rYWl2ZS9zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9zZW50X2RvY3MvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3Mvc2VudF9kb2NzL3N0eWxlcy5qcyJdLCJzb3VyY2VzQ29udGVudCI6WyIndXNlIHN0cmljdCc7XG5cbnZhciBfZG9jQ29udGV4dCA9IHJlcXVpcmUoJy4vZG9jLWNvbnRleHQuanMnKTtcblxudmFyIF9kb2NDb250ZXh0MiA9IF9pbnRlcm9wUmVxdWlyZURlZmF1bHQoX2RvY0NvbnRleHQpO1xuXG5mdW5jdGlvbiBfaW50ZXJvcFJlcXVpcmVEZWZhdWx0KG9iaikgeyByZXR1cm4gb2JqICYmIG9iai5fX2VzTW9kdWxlID8gb2JqIDogeyBkZWZhdWx0OiBvYmogfTsgfVxuXG52YXIgUmVhY3RET00gPSByZXF1aXJlKCdyZWFjdC1kb20nKTtcblxudmFyIF9yZXF1aXJlID0gcmVxdWlyZSgncmVhY3Qtcm91dGVyLWRvbScpLFxuICAgIEJyb3dzZXJSb3V0ZXIgPSBfcmVxdWlyZS5Ccm93c2VyUm91dGVyO1xuXG52YXIgRG9jID0gcmVxdWlyZSgnLi4vZnJvbnRlbmQvbW9kdWxlcy9sYXBzZWQuanN4Jyk7XG5cblxuaW5pdERhdGEgPSBKU09OLnBhcnNlKGluaXREYXRhKTtcbnVzZXJEYXRhID0gSlNPTi5wYXJzZSh1c2VyRGF0YSk7XG5cbl9kb2NDb250ZXh0Mi5kZWZhdWx0LmluaXREYXRhID0gaW5pdERhdGE7XG5fZG9jQ29udGV4dDIuZGVmYXVsdC51c2VyRGF0YSA9IHVzZXJEYXRhO1xuX2RvY0NvbnRleHQyLmRlZmF1bHQubW9kdWxlID0gJ2xhcHNlZCc7XG5cblJlYWN0RE9NLmh5ZHJhdGUoUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICBCcm93c2VyUm91dGVyLFxuICAgIG51bGwsXG4gICAgUmVhY3QuY3JlYXRlRWxlbWVudChEb2MsIHsgaW5pdERhdGE6IGluaXREYXRhLFxuICAgICAgICB1c2VyRGF0YTogdXNlckRhdGEsXG4gICAgICAgIG1vZHVsZTogJ2xhcHNlZCdcbiAgICB9KVxuKSwgZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2RvYycpKTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2xhcHNlZC5qc1xuLy8gbW9kdWxlIGlkID0gMFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfZXh0ZW5kcyA9IE9iamVjdC5hc3NpZ24gfHwgZnVuY3Rpb24gKHRhcmdldCkgeyBmb3IgKHZhciBpID0gMTsgaSA8IGFyZ3VtZW50cy5sZW5ndGg7IGkrKykgeyB2YXIgc291cmNlID0gYXJndW1lbnRzW2ldOyBmb3IgKHZhciBrZXkgaW4gc291cmNlKSB7IGlmIChPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwoc291cmNlLCBrZXkpKSB7IHRhcmdldFtrZXldID0gc291cmNlW2tleV07IH0gfSB9IHJldHVybiB0YXJnZXQ7IH07XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcblxudmFyIE1lbnUgPSByZXF1aXJlKCcuLy4uL2NvbXBvbmVudHMvbWVudS10b29sYmFyL21lbnUtdG9vbGJhci5qc3gnKTtcbnZhciBKb3VybmFsRG9jdW1lbnQgPSByZXF1aXJlKCcuLi9kb2NzL2pvdXJuYWwvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG5cbnZhciBMYXBzZURva3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2xhcHMvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG52YXIgTGFzdGVSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9sYXBzL2luZGV4LmpzeCcpO1xuXG52YXIgTGFzdGVUZWVudXN0UmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3MvbGFwc2Vfa2FhcnQvaW5kZXguanN4Jyk7XG52YXIgTGFwc2VLYWFydERva3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2xhcHNlX2thYXJ0L2RvY3VtZW50L2luZGV4LmpzeCcpO1xuXG52YXIgTGFzdGVUYWFiZWxSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9sYXBzZV90YWFiZWwvaW5kZXguanN4Jyk7XG52YXIgTGFwc2VUYWFiZWxEb2t1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9sYXBzZV90YWFiZWwvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG5cbnZhciBWYW5lbURva3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL3ZhbmVtL2RvY3VtZW50L2luZGV4LmpzeCcpO1xudmFyIFZhbmVtYXRlUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3MvdmFuZW0vaW5kZXguanN4Jyk7XG5cbnZhciBBcnZlZGVSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9hcnYvaW5kZXguanN4Jyk7XG52YXIgQXJ2ZURvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2Fydi9kb2N1bWVudC9pbmRleC5qc3gnKTtcblxudmFyIFNta1JlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL3Ntay9pbmRleC5qc3gnKTtcbnZhciBTbWtEb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9zbWsvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG5cbnZhciBTb3JkZXJpZGVSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9zb3JkZXIvaW5kZXguanN4Jyk7XG52YXIgU29yZGVyRG9jdW1lbnQgPSByZXF1aXJlKCcuLy4uL2RvY3Mvc29yZGVyL2RvY3VtZW50L2luZGV4LmpzeCcpO1xuXG52YXIgTm9tUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3Mvbm9tZW5jbGF0dXJlL2luZGV4LmpzeCcpLFxuICAgIE5vbURvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL25vbWVuY2xhdHVyZS9kb2N1bWVudC9pbmRleC5qc3gnKTtcblxudmFyIFR1bm51c1JlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL3R1bm51cy9pbmRleC5qc3gnKSxcbiAgICBUdW5udXNEb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy90dW5udXMvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG5cbnZhciBBc3V0dXNSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9hc3V0dXNlZC9pbmRleC5qc3gnKSxcbiAgICBBc3V0dXNEb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9hc3V0dXNlZC9kb2N1bWVudC9pbmRleC5qc3gnKTtcblxudmFyIExhcHNlR3J1cHBSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9sYXBzZV9ncnVwcC9pbmRleC5qc3gnKSxcbiAgICBMYXBzZUdydXBwRG9jdW1lbnQgPSByZXF1aXJlKCcuLy4uL2RvY3MvbGFwc2VfZ3J1cHAvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG5cbnZhciBQYW5rVlZSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9wYW5rX3Z2L2luZGV4LmpzeCcpO1xudmFyIENvbmZpZ0RvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2NvbmZpZy9kb2N1bWVudC9pbmRleC5qc3gnKTtcbnZhciBSZWt2RG9jdW1lbnQgPSByZXF1aXJlKCcuLy4uL2RvY3MvcmVrdi9kb2N1bWVudC9pbmRleC5qc3gnKTtcbnZhciBEb2twcm9wc0RvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2Rva3Byb3BzL2RvY3VtZW50L2luZGV4LmpzeCcpO1xudmFyIFVzZXJEb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy91c2VyaWQvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG5cbnZhciBJbmYzUmVwb3J0ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2luZjMvaW5kZXguanN4Jyk7XG52YXIgQ2hpbGRTdW1tYXJ5UmVwb3J0ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2NoaWxkX3N1bW1hcnkvaW5kZXguanN4Jyk7XG52YXIgQXJ2ZWRLb29kaUphcmdpUmVwb3J0ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2FydmVkX2tvb2RpX2phcmdpL2luZGV4LmpzeCcpO1xudmFyIFNhbGRvSmFLYWl2ZVJlcG9ydCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9zYWxkb19qYV9rYWl2ZS9pbmRleC5qc3gnKTtcbnZhciBTZW50RG9jc1JlcG9ydCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9zZW50X2RvY3MvaW5kZXguanN4Jyk7XG5cbnZhciBfcmVxdWlyZSA9IHJlcXVpcmUoJ3JlYWN0LXJvdXRlci1kb20nKSxcbiAgICBSb3V0ZSA9IF9yZXF1aXJlLlJvdXRlLFxuICAgIFJlZGlyZWN0ID0gX3JlcXVpcmUuUmVkaXJlY3Q7XG5cbnZhciBfcmVxdWlyZTIgPSByZXF1aXJlKCdyYWRpdW0nKSxcbiAgICBTdHlsZVJvb3QgPSBfcmVxdWlyZTIuU3R5bGVSb290O1xuXG52YXIgTU9EVUxFID0gJ0xhcHNlZCc7XG52YXIgRG9jQ29udGV4dCA9IHJlcXVpcmUoJy4vLi4vZG9jLWNvbnRleHQuanMnKTtcblxudmFyIEFwcCA9IGZ1bmN0aW9uIChfUmVhY3QkQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKEFwcCwgX1JlYWN0JENvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBBcHAocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIEFwcCk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKEFwcC5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKEFwcCkpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5wcmVwYXJlUGFyYW1zRm9yVG9vbGJhciA9IF90aGlzLnByZXBhcmVQYXJhbXNGb3JUb29sYmFyLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5jb21wb25ldHMgPSB7fTtcbiAgICAgICAgX3RoaXMucHJlcGFyZUNvbXBvbmVudHMoX3RoaXMuY29tcG9uZXRzKTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhBcHAsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICB2YXIgX3RoaXMyID0gdGhpcztcblxuICAgICAgICAgICAgdmFyIGJ0blBhcmFtcyA9IHRoaXMucHJlcGFyZVBhcmFtc0ZvclRvb2xiYXIoKTtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgIFN0eWxlUm9vdCxcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgcGF0aDogJy9sYXBzZWQnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KE1lbnUsIHsgcGFyYW1zOiBidG5QYXJhbXMsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaGlzdG9yeTogX3RoaXMyLnByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVrdklkOiBEb2NDb250ZXh0LnVzZXJEYXRhID8gRG9jQ29udGV4dC51c2VyRGF0YS5hc3V0dXNJZCA6IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kdWxlOiBNT0RVTEUgfSk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZCcsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChMYXN0ZVJlZ2lzdGVyLCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZHVsZTogTU9EVUxFIH0pO1xuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvbGFwcycsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChMYXN0ZVJlZ2lzdGVyLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSwgbW9kdWxlOiBNT0RVTEUgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvbGFwcy86ZG9jSWQnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoTGFwc2VEb2t1bWVudCwgX2V4dGVuZHMoe30sIHByb3BzLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnkgfSkpO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL2FzdXR1c2VkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KEFzdXR1c1JlZ2lzdGVyLCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZHVsZTogTU9EVUxFIH0pO1xuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvYXN1dHVzZWQvOmRvY0lkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KEFzdXR1c0RvY3VtZW50LCBfZXh0ZW5kcyh7fSwgcHJvcHMsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSB9KSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvbGFwc2VfZ3J1cHAnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoTGFwc2VHcnVwcFJlZ2lzdGVyLCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZHVsZTogTU9EVUxFIH0pO1xuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvbGFwc2VfZ3J1cHAvOmRvY0lkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KExhcHNlR3J1cHBEb2N1bWVudCwgX2V4dGVuZHMoe30sIHByb3BzLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnkgfSkpO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3ZhbmVtJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFZhbmVtYXRlUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLCBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC92YW5lbS86ZG9jSWQnLCBjb21wb25lbnQ6IFZhbmVtRG9rdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvbGFwc2Vfa2FhcnQnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoTGFzdGVUZWVudXN0UmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLCBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9sYXBzZV9rYWFydC86ZG9jSWQnLCBjb21wb25lbnQ6IExhcHNlS2FhcnREb2t1bWVudCB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9sYXBzZV90YWFiZWwnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoTGFzdGVUYWFiZWxSZWdpc3RlciwgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEsIG1vZHVsZTogTU9EVUxFIH0pO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL2xhcHNlX3RhYWJlbC86ZG9jSWQnLCBjb21wb25lbnQ6IExhcHNlVGFhYmVsRG9rdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvYXJ2JyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KEFydmVkZVJlZ2lzdGVyLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSwgbW9kdWxlOiBNT0RVTEUgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvYXJ2Lzpkb2NJZCcsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChBcnZlRG9jdW1lbnQsIF9leHRlbmRzKHt9LCBwcm9wcywgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5IH0pKTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9qb3VybmFsLzpkb2NJZCcsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChKb3VybmFsRG9jdW1lbnQsIF9leHRlbmRzKHt9LCBwcm9wcywgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5IH0pKTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3NtaycsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChTbWtSZWdpc3RlciwgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kdWxlOiBNT0RVTEUgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvc21rLzpkb2NJZCcsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChTbWtEb2N1bWVudCwgX2V4dGVuZHMoe30sIHByb3BzLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnkgfSkpO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3NvcmRlcicsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChTb3JkZXJpZGVSZWdpc3Rlciwge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3NvcmRlci86ZG9jSWQnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU29yZGVyRG9jdW1lbnQsIF9leHRlbmRzKHt9LCBwcm9wcywgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5IH0pKTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9ub21lbmNsYXR1cmUnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoTm9tUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhLCBtb2R1bGU6IE1PRFVMRSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9ub21lbmNsYXR1cmUvOmRvY0lkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KE5vbURvY3VtZW50LCBfZXh0ZW5kcyh7fSwgcHJvcHMsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2R1bGU6IE1PRFVMRSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5XG4gICAgICAgICAgICAgICAgICAgICAgICB9KSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvdHVubnVzLzpkb2NJZCcsIGNvbXBvbmVudDogVHVubnVzRG9jdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvdHVubnVzJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFR1bm51c1JlZ2lzdGVyLCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kdWxlOiBNT0RVTEUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhIH0pO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3BhbmtfdnYnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUGFua1ZWUmVnaXN0ZXIsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2R1bGU6IE1PRFVMRSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvY29uZmlnLzpkb2NJZCcsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChDb25maWdEb2N1bWVudCwgX2V4dGVuZHMoe30sIHByb3BzLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnkgfSkpO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL2NvbmZpZycsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChSZWRpcmVjdCwgeyB0bzogJy9sYXBzZWQvY29uZmlnLycgKyBEb2NDb250ZXh0LnVzZXJEYXRhLmFzdXR1c0lkIH0pO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3Jla3YvOmRvY0lkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFJla3ZEb2N1bWVudCwgX2V4dGVuZHMoe30sIHByb3BzLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnkgfSkpO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3Jla3YnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUmVkaXJlY3QsIHsgdG86ICcvbGFwc2VkL3Jla3YvJyArIERvY0NvbnRleHQudXNlckRhdGEuYXN1dHVzSWQgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvZG9rcHJvcHMvOmRvY0lkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERva3Byb3BzRG9jdW1lbnQsIF9leHRlbmRzKHt9LCBwcm9wcywgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5IH0pKTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC91c2VyaWQvOmRvY0lkJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFVzZXJEb2N1bWVudCwgX2V4dGVuZHMoe30sIHByb3BzLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnkgfSkpO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3VzZXJpZC8nLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUmVkaXJlY3QsIHsgdG86ICcvbGFwc2VkL3VzZXJpZC8nICsgRG9jQ29udGV4dC51c2VyRGF0YS5pZCB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9pbmYzJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KEluZjNSZXBvcnQsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2R1bGU6IE1PRFVMRSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvbGFwc19rb2trdXZvdHRlJyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KENoaWxkU3VtbWFyeVJlcG9ydCwge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZHVsZTogTU9EVUxFLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL2xhcHNlZC9hcnZlZF9rb29kaV9qYXJnaScsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChBcnZlZEtvb2RpSmFyZ2lSZXBvcnQsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBtb2R1bGU6IE1PRFVMRSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9sYXBzZWQvc2FsZG9famFfa2FpdmUnLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2FsZG9KYUthaXZlUmVwb3J0LCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kdWxlOiBNT0RVTEUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhIH0pO1xuICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvbGFwc2VkL3NlbnRfZG9jcycsXG4gICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChTZW50RG9jc1JlcG9ydCwge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZHVsZTogTU9EVUxFLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSB9KTtcbiAgICAgICAgICAgICAgICAgICAgfSB9KVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncHJlcGFyZVBhcmFtc0ZvclRvb2xiYXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcHJlcGFyZVBhcmFtc0ZvclRvb2xiYXIoKSB7XG4gICAgICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgICAgIGJ0blN0YXJ0OiB7XG4gICAgICAgICAgICAgICAgICAgIHNob3c6IHRydWVcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIGJ0bkxvZ2luOiB7XG4gICAgICAgICAgICAgICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgYnRuQWNjb3VudDoge1xuICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIH07XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3ByZXBhcmVDb21wb25lbnRzJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHByZXBhcmVDb21wb25lbnRzKGNvbXBvbmVudHMpIHtcbiAgICAgICAgICAgIHJldHVybiBjb21wb25lbnRzWydMYXBzZURvY3VtZW50J10gPSBmdW5jdGlvbiAocHJvcHMpIHtcbiAgICAgICAgICAgICAgICB2YXIgTGFwc2VEb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9sYXBzL2RvY3VtZW50L2luZGV4LmpzeCcpO1xuICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KExhcHNlRG9jdW1lbnQsIHByb3BzKTtcbiAgICAgICAgICAgIH07XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gQXBwO1xufShSZWFjdC5Db21wb25lbnQpO1xuXG5tb2R1bGUuZXhwb3J0cyA9IEFwcDtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL21vZHVsZXMvbGFwc2VkLmpzeFxuLy8gbW9kdWxlIGlkID0gNDhcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBEb2NDb250ZXh0ID0gcmVxdWlyZSgnLi4vLi4vLi4vZG9jLWNvbnRleHQnKTtcblxudmFyIFByb3BUeXBlcyA9IHJlcXVpcmUoJ3Byb3AtdHlwZXMnKTtcbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgX2ZldGNoRGF0YSA9IHJlcXVpcmUoJy4vLi4vLi4vLi4vLi4vbGlicy9mZXRjaERhdGEnKTtcblxudmFyIERvY3VtZW50VGVtcGxhdGUgPSByZXF1aXJlKCcuLi8uLi9kb2N1bWVudFRlbXBsYXRlL2luZGV4LmpzeCcpLFxuICAgIElucHV0VGV4dCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtdGV4dC9pbnB1dC10ZXh0LmpzeCcpLFxuICAgIFRleHRBcmVhID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy90ZXh0LWFyZWEvdGV4dC1hcmVhLmpzeCcpLFxuICAgIERhdGFHcmlkID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9kYXRhLWdyaWQvZGF0YS1ncmlkLmpzeCcpLFxuICAgIHN0eWxlcyA9IHJlcXVpcmUoJy4vbGFwcy5zdHlsZXMnKTtcblxudmFyIExJQlJBUklFUyA9IFtdO1xuXG52YXIgTGFwcyA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhMYXBzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBMYXBzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBMYXBzKTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoTGFwcy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKExhcHMpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMuc3RhdGUgPSB7XG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCksXG4gICAgICAgICAgICB2YW5lbUlkOiBudWxsLFxuICAgICAgICAgICAgbW9kdWxlOiAnbGFwc2VkJ1xuICAgICAgICB9O1xuXG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmhhbmRsZVBhZ2VDbGljayA9IF90aGlzLmhhbmRsZVBhZ2VDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlR3JpZEJ0bkNsaWNrID0gX3RoaXMuaGFuZGxlR3JpZEJ0bkNsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5mZXRjaERhdGEgPSBfdGhpcy5mZXRjaERhdGEuYmluZChfdGhpcyk7XG5cbiAgICAgICAgX3RoaXMuZG9jSWQgPSBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCk7XG5cbiAgICAgICAgX3RoaXMucGFnZXMgPSBbeyBwYWdlTmFtZTogJ0xhcHNlIGthYXJ0JywgZG9jVHlwZUlkOiAnTEFQUycgfSwgeyBwYWdlTmFtZTogJ1RhYWJlbCcsIGhhbmRsZVBhZ2VDbGljazogX3RoaXMuaGFuZGxlUGFnZUNsaWNrLCBkb2NUeXBlSWQ6ICdMQVBTRV9UQUFCRUwnIH0sIHsgcGFnZU5hbWU6ICdBcnZlZCcsIGhhbmRsZVBhZ2VDbGljazogX3RoaXMuaGFuZGxlUGFnZUNsaWNrLCBkb2NUeXBlSWQ6ICdBUlYnIH0sIHsgcGFnZU5hbWU6ICdNYWtzZWtvcmFsZHVzZWQnLCBoYW5kbGVQYWdlQ2xpY2s6IF90aGlzLmhhbmRsZVBhZ2VDbGljaywgZG9jVHlwZUlkOiAnU01LJyB9LCB7IHBhZ2VOYW1lOiAnS2Fzc2FvcmRlcmlkJywgaGFuZGxlUGFnZUNsaWNrOiBfdGhpcy5oYW5kbGVQYWdlQ2xpY2ssIGRvY1R5cGVJZDogJ1NPUkRFUicgfV07XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoTGFwcywgW3tcbiAgICAgICAga2V5OiAnY29tcG9uZW50RGlkTW91bnQnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gY29tcG9uZW50RGlkTW91bnQoKSB7XG4gICAgICAgICAgICBpZiAodGhpcy5wcm9wcy5oaXN0b3J5ICYmIHRoaXMucHJvcHMuaGlzdG9yeS5sb2NhdGlvbi5zdGF0ZSkge1xuICAgICAgICAgICAgICAgIHZhciB2YW5lbUlkID0gdGhpcy5wcm9wcy5oaXN0b3J5LmxvY2F0aW9uLnN0YXRlLnZhbmVtSWQ7XG4gICAgICAgICAgICAgICAgdmFyIF9tb2R1bGUgPSB0aGlzLnByb3BzLmhpc3RvcnkubG9jYXRpb24uc3RhdGUubW9kdWxlID8gdGhpcy5wcm9wcy5oaXN0b3J5LmxvY2F0aW9uLnN0YXRlLm1vZHVsZSA6ICdsYXBzZWQnO1xuICAgICAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyB2YW5lbUlkOiB2YW5lbUlkLCBtb2R1bGU6IF9tb2R1bGUgfSk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIC8v0YHQvtGF0YDQsNC90LjQvCDQv9C+0YHQu9C10LTQvdC40LkgZG9jSWRcbiAgICAgICAgICAgIGlmICh0aGlzLnN0YXRlLmRvY0lkKSB7XG4gICAgICAgICAgICAgICAgRG9jQ29udGV4dC5sYXBzSWQgPSB0aGlzLnN0YXRlLmRvY0lkO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFRlbXBsYXRlLCB7IGRvY0lkOiB0aGlzLnN0YXRlLmRvY0lkLFxuICAgICAgICAgICAgICAgIHJlZjogJ2RvY3VtZW50JyxcbiAgICAgICAgICAgICAgICBoaXN0b3J5OiB0aGlzLnByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnN0YXRlLm1vZHVsZSxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6ICdMQVBTJyxcbiAgICAgICAgICAgICAgICBpbml0RGF0YTogdGhpcy5wcm9wcy5pbml0RGF0YSA/IHRoaXMucHJvcHMuaW5pdERhdGEgOiB7fSxcbiAgICAgICAgICAgICAgICBsaWJzOiBMSUJSQVJJRVMsXG4gICAgICAgICAgICAgICAgcGFnZXM6IHRoaXMucGFnZXMsXG4gICAgICAgICAgICAgICAgcmVuZGVyZXI6IHRoaXMucmVuZGVyZXIsXG4gICAgICAgICAgICAgICAgaGFuZGxlR3JpZEJ0bkNsaWNrOiB0aGlzLmhhbmRsZUdyaWRCdG5DbGljayxcbiAgICAgICAgICAgICAgICBmb2N1c0VsZW1lbnQ6ICdpbnB1dC1pc2lrdWtvb2QnXG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAq0JLQtdGA0L3QtdGCINC60LDRgdGC0L7QvNC90YvQtSDQutC+0LzQv9C+0L3QtdC90YLRiyDQtNC+0LrRg9C80LXQvdGC0LBcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgdmFyIGlzRWRpdE1vZGUgPSBzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICBncmlkVmFuZW1hZERhdGEgPSBzZWxmLmRvY0RhdGEudmFuZW1hZCxcbiAgICAgICAgICAgICAgICBncmlkVmFuZW1hZENvbHVtbnMgPSBzZWxmLmRvY0RhdGEuZ3JpZENvbmZpZyxcbiAgICAgICAgICAgICAgICBncmlkVGVlbnVzdGVEYXRhID0gc2VsZi5kb2NEYXRhLnRlZW51c2VkLFxuICAgICAgICAgICAgICAgIGdyaWRUZWVudXN0ZUNvbHVtbnMgPSBzZWxmLmRvY0RhdGEuZ3JpZFRlZW51c3RlQ29uZmlnO1xuXG4gICAgICAgICAgICBpZiAoc2VsZi5kb2NEYXRhLmlkID09PSAwKSB7XG4gICAgICAgICAgICAgICAgLy9uZWV3IHJlY29yZFxuICAgICAgICAgICAgICAgIHNlbGYuZG9jRGF0YS52YW5lbWlkID0gdGhpcy5zdGF0ZS52YW5lbUlkO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAoIXRoaXMuZG9jSWQgJiYgc2VsZi5kb2NEYXRhLmlkKSB7XG4gICAgICAgICAgICAgICAgdGhpcy5kb2NJZCA9IHNlbGYuZG9jRGF0YS5pZDtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvYyB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHJlZjogJ2lucHV0LWlzaWt1a29vZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdJc2lrdWtvb2Q6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnaXNpa3Vrb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmlzaWt1a29vZCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbWF4TGVuZ3RoOiAnMTEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdOaW1pOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ25pbWknLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubmltaSB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1uaW1pJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ1ZpaXRlbnVtYmVyOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3ZpaXRlbnVtYmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnZpaXRlbnVtYmVyIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXZpaXRlbnVtYmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyByZWY6ICdpbnB1dC1qYWFrJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aXRsZTogJ0pcXHhFNFxceEU0azonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdqYWFrJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmphYWsgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6IHRydWVcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdNXFx4RTRya3VzZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ211dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubXV1ZCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdsYWJlbCcsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ2xhYmVsJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgJ1ZhbmVtYWQnXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRGF0YUdyaWQsIHsgc291cmNlOiAndmFuZW1hZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBncmlkRGF0YTogZ3JpZFZhbmVtYWREYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZENvbHVtbnM6IGdyaWRWYW5lbWFkQ29sdW1ucyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHNob3dUb29sQmFyOiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogc2VsZi5oYW5kbGVHcmlkQnRuQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMuZ3JpZC5oZWFkZXJUYWJsZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ3ZhbmVtJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3ZhbmVtYWQtZGF0YS1ncmlkJyB9KVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdsYWJlbCcsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ2xhYmVsJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgJ1RlZW51c2VkJ1xuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KERhdGFHcmlkLCB7IHNvdXJjZTogJ3RlZW51c2VkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIGdyaWREYXRhOiBncmlkVGVlbnVzdGVEYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZENvbHVtbnM6IGdyaWRUZWVudXN0ZUNvbHVtbnMsXG4gICAgICAgICAgICAgICAgICAgICAgICBzaG93VG9vbEJhcjogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICBoYW5kbGVHcmlkQnRuQ2xpY2s6IHNlbGYuaGFuZGxlR3JpZEJ0bkNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgZG9jVHlwZUlkOiAnbGFwc2Vfa2FhcnQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGU6IHN0eWxlcy5ncmlkLmhlYWRlclRhYmxlLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGVlbnVzdGUtZGF0YS1ncmlkJyB9KVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVBhZ2VDbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVQYWdlQ2xpY2socGFnZURvY1R5cGVJZCkge1xuICAgICAgICAgICAgLy8g0LTQsNC90L3Ri9C1INC00LvRjyDRhNC40LvRjNGC0YDQsFxuICAgICAgICAgICAgdmFyIGlzaWt1a29vZCA9IHRoaXMucmVmc1snZG9jdW1lbnQnXS5kb2NEYXRhLmlzaWt1a29vZDtcblxuICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goe1xuICAgICAgICAgICAgICAgIHBhdGhuYW1lOiAnL2xhcHNlZC8nICsgcGFnZURvY1R5cGVJZCxcbiAgICAgICAgICAgICAgICBzdGF0ZTogeyBpc2lrdWtvb2Q6IGlzaWt1a29vZCwgdHlwZTogJ3RleHQnIH1cbiAgICAgICAgICAgIH0pO1xuICAgICAgICB9XG5cbiAgICAgICAgLy8g0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0LrQu9C40Log0L3QsCDQs9GA0LjQtNC1INGA0L7QtNC40YLQtdC70LXQuVxuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdoYW5kbGVHcmlkQnRuQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaGFuZGxlR3JpZEJ0bkNsaWNrKGJ0bk5hbWUsIGFjdGl2ZVJvdywgaWQsIGRvY1R5cGVJZCkge1xuICAgICAgICAgICAgdmFyIF90aGlzMiA9IHRoaXM7XG5cbiAgICAgICAgICAgIHN3aXRjaCAoYnRuTmFtZS50b1VwcGVyQ2FzZSgpKSB7XG4gICAgICAgICAgICAgICAgY2FzZSBcIkVESVRcIjpcblxuICAgICAgICAgICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCh7XG4gICAgICAgICAgICAgICAgICAgICAgICBwYXRobmFtZTogJy9sYXBzZWQvJyArIGRvY1R5cGVJZCArICcvJyArIGlkLFxuICAgICAgICAgICAgICAgICAgICAgICAgc3RhdGU6IHsgbGFwc0lkOiB0aGlzLmRvY0lkLCBtb2R1bGU6IHRoaXMuc3RhdGUubW9kdWxlIH1cbiAgICAgICAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIGNhc2UgXCJBRERcIjpcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goe1xuICAgICAgICAgICAgICAgICAgICAgICAgcGF0aG5hbWU6ICcvbGFwc2VkLycgKyBkb2NUeXBlSWQgKyAnLzAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgc3RhdGU6IHsgbGFwc0lkOiB0aGlzLmRvY0lkLCBtb2R1bGU6IHRoaXMuc3RhdGUubW9kdWxlIH1cbiAgICAgICAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIGNhc2UgXCJERUxFVEVcIjpcbiAgICAgICAgICAgICAgICAgICAgLy9zZW5kIHBvc3QgdG8gZGVsZXRlIHJvd1xuICAgICAgICAgICAgICAgICAgICB0aGlzLmZldGNoRGF0YShkb2NUeXBlSWQsIGlkKS50aGVuKGZ1bmN0aW9uICgpIHtcblxuICAgICAgICAgICAgICAgICAgICAgICAgdmFyIGN1cnJlbnQgPSBfdGhpczIucHJvcHMubG9jYXRpb24ucGF0aG5hbWU7XG4gICAgICAgICAgICAgICAgICAgICAgICBfdGhpczIucHJvcHMuaGlzdG9yeS5yZXBsYWNlKCcvcmVsb2FkJyk7XG4gICAgICAgICAgICAgICAgICAgICAgICBzZXRUaW1lb3V0KGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBfdGhpczIucHJvcHMuaGlzdG9yeS5yZXBsYWNlKGN1cnJlbnQpO1xuICAgICAgICAgICAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICBkZWZhdWx0OlxuICAgICAgICAgICAgICAgICAgICBjb25zb2xlLmxvZygnVmlnYW5lIGNsaWNrJyk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICAvLyDQvtGC0L/RgNCw0LLQuNGCINC30LDQv9GA0L7RgSDQvdCwINGD0LTQsNC70LXQvdC40LUg0YEg0L/QsNGA0LDQvNC10YLRgNC+0Lwg0YLQuNC/INC00L7QutGD0LzQtdC90YLQsCDQuCDQuNC0XG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2ZldGNoRGF0YScsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBmZXRjaERhdGEoZG9jVHlwZUlkLCBpZCkge1xuXG4gICAgICAgICAgICB2YXIgdXJsID0gJy9uZXdBcGkvZGVsZXRlJztcblxuICAgICAgICAgICAgdmFyIHBhcmFtcyA9IHtcbiAgICAgICAgICAgICAgICBwYXJhbWV0ZXI6IGRvY1R5cGVJZCxcbiAgICAgICAgICAgICAgICBtb2R1bGU6ICdsYXBzZWQnLFxuICAgICAgICAgICAgICAgIHVzZXJJZDogRG9jQ29udGV4dC51c2VyRGF0YS51c2VySWQsXG4gICAgICAgICAgICAgICAgdXVpZDogRG9jQ29udGV4dC51c2VyRGF0YS51dWlkLFxuICAgICAgICAgICAgICAgIGRvY0lkOiBpZFxuICAgICAgICAgICAgfTtcblxuICAgICAgICAgICAgcmV0dXJuIF9mZXRjaERhdGFbJ2ZldGNoRGF0YVBvc3QnXSh1cmwsIHBhcmFtcyk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gTGFwcztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbkxhcHMucHJvcFR5cGVzID0ge1xuICAgIGRvY0lkOiBQcm9wVHlwZXMubnVtYmVyLFxuICAgIGluaXREYXRhOiBQcm9wVHlwZXMub2JqZWN0LFxuICAgIHVzZXJEYXRhOiBQcm9wVHlwZXMub2JqZWN0XG59O1xuXG5MYXBzLmRlZmF1bHRQcm9wcyA9IHtcbiAgICBwYXJhbXM6IHsgZG9jSWQ6IDAgfSxcbiAgICBpbml0RGF0YToge30sXG4gICAgdXNlckRhdGE6IHt9XG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IExhcHM7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHMvZG9jdW1lbnQvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyMjNcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBkb2NSb3c6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAncm93J1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsdWUnXHJcbiAgICAgICAgKi9cbiAgICB9LFxuICAgIGRvY0NvbHVtbjoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nLFxuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIHllbGxvdycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgd2lkdGg6ICc1MCUnXG4gICAgfSxcbiAgICBkb2M6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJ1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJyb3duJ1xyXG4gICAgICAgICovXG4gICAgfSxcblxuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9LFxuXG4gICAgZ3JpZFJvdzoge1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsYWNrJyxcclxuICAgICAgICAqL1xuICAgICAgICBiYWNrZ3JvdW5kQ29sb3I6ICd3aGl0ZScsXG4gICAgICAgIHBvc2l0aW9uOiAncmVsYXRpdmUnLFxuICAgICAgICBtYXJnaW46ICcxMCUgMzAlIDEwJSAzMCUnLFxuICAgICAgICB3aWR0aDogJ2F1dG8nLFxuICAgICAgICBvcGFjaXR5OiAnMScsXG4gICAgICAgIHRvcDogJzEwMHB4J1xuICAgIH1cblxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvbGFwcy9kb2N1bWVudC9sYXBzLnN0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjI0XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIERvY3VtZW50UmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3VtZW50cy9kb2N1bWVudHMuanN4Jyk7XG52YXIgQnRuQXJ2ZXN0YSA9IHJlcXVpcmUoJy4vLi4vLi4vY29tcG9uZW50cy9idXR0b24tcmVnaXN0ZXIvYnV0dG9uLXRhc2svaW5kZXguanN4Jyk7XG52YXIgVG9vbGJhckNvbnRhaW5lciA9IHJlcXVpcmUoJy4vLi4vLi4vY29tcG9uZW50cy90b29sYmFyLWNvbnRhaW5lci90b29sYmFyLWNvbnRhaW5lci5qc3gnKTtcblxudmFyIHN0eWxlcyA9IHJlcXVpcmUoJy4vbGFwcy1yZWdpc3Rlci1zdHlsZXMnKTtcbnZhciBET0NfVFlQRV9JRCA9ICdMQVBTJztcbnZhciBFVkVOVFMgPSBbeyBuYW1lOiAnVGFiZWxpIGtvb3N0YW1pbmUnLCBtZXRob2Q6ICdhcnZlc3RhVGFhYmVsJywgZG9jVHlwZUlkOiAnbGFwc2VfdGFhYmVsJyB9LCB7IG5hbWU6ICdBcnZlIGtvb3N0YW1pbmUnLCBtZXRob2Q6ICdrb29zdGFBcnZlJywgZG9jVHlwZUlkOiAnYXJ2JyB9LCB7IG5hbWU6ICdFdHRlbWFrc3VhcnZlIGtvb3N0YW1pbmUnLCBtZXRob2Q6ICdrb29zdGFFdHRlbWFrc3VBcnZlJywgZG9jVHlwZUlkOiAnYXJ2JyB9XTtcblxuLyoqXHJcbiAqINCa0LvQsNGB0YEg0YDQtdCw0LvQuNC30YPQtdGCINC00L7QutGD0LzQtdC90YIg0YHQv9GA0LDQstC+0YfQvdC40LrQsCDQv9GA0LjQt9C90LDQutC+0LIuXHJcbiAqL1xuXG52YXIgRG9jdW1lbnRzID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKERvY3VtZW50cywgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gRG9jdW1lbnRzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBEb2N1bWVudHMpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChEb2N1bWVudHMuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihEb2N1bWVudHMpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMub25DbGlja0hhbmRsZXIgPSBfdGhpcy5vbkNsaWNrSGFuZGxlci5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMucmVuZGVyZXIgPSBfdGhpcy5yZW5kZXJlci5iaW5kKF90aGlzKTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2N1bWVudHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFJlZ2lzdGVyLCB7IGluaXREYXRhOiB0aGlzLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSA/IHRoaXMucHJvcHMuaGlzdG9yeSA6IG51bGwsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnByb3BzLm1vZHVsZSxcbiAgICAgICAgICAgICAgICByZWY6ICdyZWdpc3RlcicsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiBET0NfVFlQRV9JRCxcbiAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLFxuICAgICAgICAgICAgICAgIHJlbmRlcjogdGhpcy5yZW5kZXJlciB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoKSB7XG4gICAgICAgICAgICB2YXIgX3RoaXMyID0gdGhpcztcblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgVG9vbGJhckNvbnRhaW5lcixcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgIEVWRU5UUy5tYXAoZnVuY3Rpb24gKGV2ZW50KSB7XG4gICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KEJ0bkFydmVzdGEsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBldmVudC5uYW1lLFxuICAgICAgICAgICAgICAgICAgICAgICAgb25DbGljazogX3RoaXMyLm9uQ2xpY2tIYW5kbGVyLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnYnRuLScgKyBldmVudC5uYW1lXG4gICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdvbkNsaWNrSGFuZGxlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBvbkNsaWNrSGFuZGxlcihldmVudCwgc2Vpc3VnYSkge1xuICAgICAgICAgICAgdmFyIF90aGlzMyA9IHRoaXM7XG5cbiAgICAgICAgICAgIHZhciBEb2MgPSB0aGlzLnJlZnNbJ3JlZ2lzdGVyJ107XG5cbiAgICAgICAgICAgIC8vINGB0L7QsdC40YDQsNC10Lwg0L/QsNGA0LDQvNC10YLRgNGLXG4gICAgICAgICAgICB2YXIgaWRzID0gW107XG4gICAgICAgICAgICBEb2MuZ3JpZERhdGEuZmlsdGVyKGZ1bmN0aW9uIChyb3cpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gcm93LnNlbGVjdDtcbiAgICAgICAgICAgIH0pLmZvckVhY2goZnVuY3Rpb24gKHJvdykge1xuICAgICAgICAgICAgICAgIGlkcy5wdXNoKHJvdy5pZCk7XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgdmFyIHRhc2sgPSBFVkVOVFMuZmluZChmdW5jdGlvbiAodGFzaykge1xuICAgICAgICAgICAgICAgIHJldHVybiB0YXNrLm5hbWUgPT09IGV2ZW50O1xuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICBpZiAoIXRhc2spIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gRG9jLnNldFN0YXRlKHsgd2FybmluZzogJ1Rhc2s6ICcgKyBldmVudCArICcgZWkgbGVpZG51ZCcsIHdhcm5pbmdUeXBlOiAnZXJyb3InIH0pO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAvLyDQvtGC0L/RgNCw0LLQu9GP0LXQvCDQt9Cw0L/RgNC+0YEg0L3QsCDQstGL0L/QvtC70L3QtdC90LjQtVxuICAgICAgICAgICAgRG9jLmZldGNoRGF0YSgnY2FsYy8nICsgdGFzay5tZXRob2QsIHsgZG9jczogaWRzLCBzZWlzdWdhOiBzZWlzdWdhIH0pLnRoZW4oZnVuY3Rpb24gKGRhdGEpIHtcbiAgICAgICAgICAgICAgICBpZiAoZGF0YS5yZXN1bHQpIHtcbiAgICAgICAgICAgICAgICAgICAgRG9jLnNldFN0YXRlKHsgd2FybmluZzogJ0tva2t1IGFydmVzdGF0dWQ6ICcgKyBkYXRhLnJlc3VsdCArICcsIHN1dW5hdGFtaW5lLi4uJywgd2FybmluZ1R5cGU6ICdvaycgfSk7XG5cbiAgICAgICAgICAgICAgICAgICAgLy8g0LbQtNC10LwgMTAg0YHQtdC6INC4INGA0LXQtNCw0LnRgNC10LrRgiDQvdCwINGC0LDQsdC10LvRj1xuICAgICAgICAgICAgICAgICAgICBzZXRUaW1lb3V0KGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIF90aGlzMy5wcm9wcy5oaXN0b3J5LnB1c2goJy9sYXBzZWQvJyArIHRhc2suZG9jVHlwZUlkKTtcbiAgICAgICAgICAgICAgICAgICAgfSwgMTAwMCAqIDUpO1xuICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgIERvYy5zZXRTdGF0ZSh7IHdhcm5pbmc6ICdUZWtraXMgdmlnYTogJyArIGRhdGEuZXJyb3JfbWVzc2FnZSwgd2FybmluZ1R5cGU6ICdub3RWYWxpZCcgfSk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gRG9jdW1lbnRzO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxubW9kdWxlLmV4cG9ydHMgPSBEb2N1bWVudHM7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHMvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyMjVcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xudmFyIGdldE5vdyA9IHJlcXVpcmUoJy4vLi4vLi4vLi4vLi4vbGlicy9nZXROb3cnKTtcblxudmFyIE1vZGFsUGFnZSA9IHJlcXVpcmUoJy4vLi4vLi4vbW9kYWxwYWdlL21vZGFsUGFnZS5qc3gnKTtcblxudmFyIHN0eWxlcyA9IHJlcXVpcmUoJy4uL2J1dHRvbi1yZWdpc3Rlci1zdHlsZXMnKSxcbiAgICBCdXR0b24gPSByZXF1aXJlKCcuLi9idXR0b24tcmVnaXN0ZXIuanN4JyksXG4gICAgSW5wdXREYXRlID0gcmVxdWlyZSgnLi4vLi4vaW5wdXQtZGF0ZS9pbnB1dC1kYXRlLmpzeCcpLFxuICAgIElucHV0TnVtYmVyID0gcmVxdWlyZSgnLi4vLi4vaW5wdXQtbnVtYmVyL2lucHV0LW51bWJlci5qc3gnKSxcbiAgICBJQ09OID0gJ2V4ZWN1dGUnO1xuXG52YXIgQnV0dG9uVGFzayA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhCdXR0b25UYXNrLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICAvLyDQutC90L7Qv9C60LAg0YHQvtC30LTQsNC90LjRjyDQtNC+0LrRg9C80LXQvdGC0LAg0LIg0YDQtdCz0LjRgdGC0YDQsNGFXG4gICAgZnVuY3Rpb24gQnV0dG9uVGFzayhwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgQnV0dG9uVGFzayk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKEJ1dHRvblRhc2suX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihCdXR0b25UYXNrKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgc2hvd01vZGFsOiBmYWxzZSxcbiAgICAgICAgICAgIHNlaXN1Z2E6IGdldE5vdygpLFxuICAgICAgICAgICAga29ndXM6IDBcbiAgICAgICAgfTtcbiAgICAgICAgX3RoaXMuaGFuZGxlQ2xpY2sgPSBfdGhpcy5oYW5kbGVDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMubW9kYWxQYWdlQ2xpY2sgPSBfdGhpcy5tb2RhbFBhZ2VDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlSW5wdXRDaGFuZ2UgPSBfdGhpcy5oYW5kbGVJbnB1dENoYW5nZS5iaW5kKF90aGlzKTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhCdXR0b25UYXNrLCBbe1xuICAgICAgICBrZXk6ICdoYW5kbGVDbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVDbGljayhlKSB7XG4gICAgICAgICAgICB0aGlzLnNldFN0YXRlKHsgc2hvd01vZGFsOiB0cnVlIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgdmFyIHZhbHVlID0gdGhpcy5wcm9wcy52YWx1ZSA/IHRoaXMucHJvcHMudmFsdWUgOiAnVMOkaXRtaW5lJztcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgQnV0dG9uLFxuICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHZhbHVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnYnRuVGFzaycsXG4gICAgICAgICAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLmJ1dHRvbixcbiAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2xpY2s6IHRoaXMuaGFuZGxlQ2xpY2sgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudCgnaW1nJywgeyByZWY6ICdpbWFnZScsIHNyYzogc3R5bGVzLmljb25zW0lDT05dIH0pXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICB0aGlzLnN0YXRlLnNob3dNb2RhbCA/IFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgIE1vZGFsUGFnZSxcbiAgICAgICAgICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgICAgICAgICAgbW9kYWxQYWdlQnRuQ2xpY2s6IHRoaXMubW9kYWxQYWdlQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICBtb2RhbFBhZ2VOYW1lOiB2YWx1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICBtb2RhbE9iamVjdHM6IFsnYnRuT2snLCAnYnRuQ2FuY2VsJ11cbiAgICAgICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICAgICAgJ0thcyBrXFx4RTRpdmF0YSBcIicgKyB2YWx1ZSArICdcIiA/JyxcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy5zaG93RGF0ZSA/IFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXREYXRlLCB7IHRpdGxlOiAnU2Vpc3VnYSAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2twdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogdGhpcy5zdGF0ZS5zZWlzdWdhLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQta3B2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiB0aGlzLmhhbmRsZUlucHV0Q2hhbmdlIH0pIDogbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy5zaG93S29ndXMgPyBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7IHRpdGxlOiB0aGlzLnByb3BzLnRpdGxlID8gdGhpcy5wcm9wcy50aXRsZSA6ICdWw6TDpHJ0dXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2tvZ3VzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIodGhpcy5zdGF0ZS5rb2d1cyksXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1rb2d1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5oYW5kbGVJbnB1dENoYW5nZSB9KSA6IG51bGxcbiAgICAgICAgICAgICAgICApIDogbnVsbFxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnbW9kYWxQYWdlQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gbW9kYWxQYWdlQ2xpY2soYnRuRXZlbnQpIHtcbiAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyBzaG93TW9kYWw6IGZhbHNlIH0pO1xuICAgICAgICAgICAgaWYgKGJ0bkV2ZW50ID09PSAnT2snKSB7XG4gICAgICAgICAgICAgICAgdGhpcy5wcm9wcy5vbkNsaWNrKHRoaXMucHJvcHMudmFsdWUsIHRoaXMucHJvcHMuc2hvd0tvZ3VzID8gdGhpcy5zdGF0ZS5rb2d1cyA6IHRoaXMuc3RhdGUuc2Vpc3VnYSk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICAvL3dpbGwgc2F2ZSB2YWx1ZVxuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdoYW5kbGVJbnB1dENoYW5nZScsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVJbnB1dENoYW5nZShuYW1lLCB2YWx1ZSkge1xuICAgICAgICAgICAgc3dpdGNoIChuYW1lKSB7XG4gICAgICAgICAgICAgICAgY2FzZSAna3B2JzpcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IHNlaXN1Z2E6IHZhbHVlIH0pO1xuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICBjYXNlICdrb2d1cyc6XG4gICAgICAgICAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyBrb2d1czogdmFsdWUgfSk7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuXG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gQnV0dG9uVGFzaztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbkJ1dHRvblRhc2suZGVmYXVsdFByb3BzID0ge1xuICAgIGRpc2FibGVkOiBmYWxzZSxcbiAgICBzaG93OiB0cnVlLFxuICAgIHNob3dEYXRlOiB0cnVlLFxuICAgIHNob3dLb2d1czogZmFsc2Vcbn07XG5cbm1vZHVsZS5leHBvcnRzID0gQnV0dG9uVGFzaztcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi10YXNrL2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMjMyXG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgZ3JpZDoge1xuICAgICAgICBtYWluVGFibGU6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfSxcbiAgICAgICAgaGVhZGVyVGFibGU6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfSxcblxuICAgICAgICBncmlkQ29udGFpbmVyOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH1cblxuICAgIH1cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHMvbGFwcy1yZWdpc3Rlci1zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDIzM1xuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcbnZhciBEb2N1bWVudFJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2N1bWVudHMvZG9jdW1lbnRzLmpzeCcpO1xudmFyIEJ0blRhc2sgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi10YXNrL2luZGV4LmpzeCcpO1xudmFyIFRvb2xiYXJDb250YWluZXIgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvdG9vbGJhci1jb250YWluZXIvdG9vbGJhci1jb250YWluZXIuanN4Jyk7XG5cbnZhciBzdHlsZXMgPSByZXF1aXJlKCcuL3N0eWxlcycpO1xudmFyIERPQ19UWVBFX0lEID0gJ0xBUFNFX0tBQVJUJztcblxuLyoqXHJcbiAqINCa0LvQsNGB0YEg0YDQtdCw0LvQuNC30YPQtdGCINC00L7QutGD0LzQtdC90YIg0YHQv9GA0LDQstC+0YfQvdC40LrQsCDQv9GA0LjQt9C90LDQutC+0LIuXHJcbiAqL1xuXG52YXIgRG9jdW1lbnRzID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKERvY3VtZW50cywgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gRG9jdW1lbnRzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBEb2N1bWVudHMpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChEb2N1bWVudHMuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihEb2N1bWVudHMpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMub25DbGlja0hhbmRsZXIgPSBfdGhpcy5vbkNsaWNrSGFuZGxlci5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMucmVuZGVyZXIgPSBfdGhpcy5yZW5kZXJlci5iaW5kKF90aGlzKTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2N1bWVudHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFJlZ2lzdGVyLCB7IGluaXREYXRhOiB0aGlzLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgIHVzZXJEYXRhOiB0aGlzLnByb3BzLnVzZXJEYXRhLFxuICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSA/IHRoaXMucHJvcHMuaGlzdG9yeSA6IG51bGwsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnByb3BzLm1vZHVsZSxcbiAgICAgICAgICAgICAgICByZWY6ICdyZWdpc3RlcicsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiBET0NfVFlQRV9JRCxcbiAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLFxuICAgICAgICAgICAgICAgIHJlbmRlcjogdGhpcy5yZW5kZXJlciB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoKSB7XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgIFRvb2xiYXJDb250YWluZXIsXG4gICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEJ0blRhc2ssIHtcbiAgICAgICAgICAgICAgICAgICAgdmFsdWU6ICdNdXVkYSBldHRlbWFrc3UgcGVyaW9kJyxcbiAgICAgICAgICAgICAgICAgICAgb25DbGljazogdGhpcy5vbkNsaWNrSGFuZGxlcixcbiAgICAgICAgICAgICAgICAgICAgc2hvd0RhdGU6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICBzaG93S29ndXM6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgIHJlZjogJ2J0bi1ldHRlbWFrc3VfcGVyaW9kJ1xuICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdvbkNsaWNrSGFuZGxlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBvbkNsaWNrSGFuZGxlcihldmVudCwgZXR0ZW1ha3N1UGVyaW9kKSB7XG4gICAgICAgICAgICB2YXIgRG9jID0gdGhpcy5yZWZzWydyZWdpc3RlciddO1xuXG4gICAgICAgICAgICAvLyDRgdC+0LHQuNGA0LDQtdC8INC/0LDRgNCw0LzQtdGC0YDRi1xuICAgICAgICAgICAgdmFyIGlkcyA9IFtdO1xuICAgICAgICAgICAgRG9jLmdyaWREYXRhLmZpbHRlcihmdW5jdGlvbiAocm93KSB7XG4gICAgICAgICAgICAgICAgaWYgKHJvdy5ldHRlbWFrcyAmJiByb3cuc2VsZWN0KSB7XG4gICAgICAgICAgICAgICAgICAgIHJldHVybiByb3c7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSkuZm9yRWFjaChmdW5jdGlvbiAocm93KSB7XG4gICAgICAgICAgICAgICAgaWRzLnB1c2gocm93LmlkKTtcbiAgICAgICAgICAgIH0pO1xuXG4gICAgICAgICAgICAvLyDQvtGC0L/RgNCw0LLQu9GP0LXQvCDQt9Cw0L/RgNC+0YEg0L3QsCDQstGL0L/QvtC70L3QtdC90LjQtVxuICAgICAgICAgICAgRG9jLmZldGNoRGF0YSgnY2FsYy9tdXVkYV9ldHRlbWFrc3VfcGVyaW9kJywgeyBkb2NzOiBpZHMsIGV0dGVtYWtzdVBlcmlvZDogZXR0ZW1ha3N1UGVyaW9kIH0pLnRoZW4oZnVuY3Rpb24gKGRhdGEpIHtcblxuICAgICAgICAgICAgICAgIGlmIChkYXRhLnJlc3VsdCkge1xuICAgICAgICAgICAgICAgICAgICBEb2Muc2V0U3RhdGUoeyB3YXJuaW5nOiAnS29ra3UgYXJ2ZXN0YXR1ZDogJyArIGRhdGEucmVzdWx0LCB3YXJuaW5nVHlwZTogJ29rJyB9KTtcbiAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICBEb2Muc2V0U3RhdGUoeyB3YXJuaW5nOiAnVGVra2lzIHZpZ2E6ICcgKyBkYXRhLmVycm9yX21lc3NhZ2UsIHdhcm5pbmdUeXBlOiAnbm90VmFsaWQnIH0pO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0pO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIERvY3VtZW50cztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gRG9jdW1lbnRzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzZV9rYWFydC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDIzNFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9XG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzZV9rYWFydC9zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDIzNVxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfZXh0ZW5kcyA9IE9iamVjdC5hc3NpZ24gfHwgZnVuY3Rpb24gKHRhcmdldCkgeyBmb3IgKHZhciBpID0gMTsgaSA8IGFyZ3VtZW50cy5sZW5ndGg7IGkrKykgeyB2YXIgc291cmNlID0gYXJndW1lbnRzW2ldOyBmb3IgKHZhciBrZXkgaW4gc291cmNlKSB7IGlmIChPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwoc291cmNlLCBrZXkpKSB7IHRhcmdldFtrZXldID0gc291cmNlW2tleV07IH0gfSB9IHJldHVybiB0YXJnZXQ7IH07XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFByb3BUeXBlcyA9IHJlcXVpcmUoJ3Byb3AtdHlwZXMnKTtcbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgRG9jQ29udGV4dCA9IHJlcXVpcmUoJy4uLy4uLy4uL2RvYy1jb250ZXh0Jyk7XG5cbnZhciBEb2N1bWVudFRlbXBsYXRlID0gcmVxdWlyZSgnLi4vLi4vZG9jdW1lbnRUZW1wbGF0ZS9pbmRleC5qc3gnKSxcbiAgICBJbnB1dE51bWJlciA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtbnVtYmVyL2lucHV0LW51bWJlci5qc3gnKSxcbiAgICBCdXR0b25FZGl0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9idXR0b24tcmVnaXN0ZXIvYnV0dG9uLXJlZ2lzdGVyLWVkaXQvYnV0dG9uLXJlZ2lzdGVyLWVkaXQuanN4JyksXG4gICAgSW5wdXREYXRlID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC1kYXRlL2lucHV0LWRhdGUuanN4JyksXG4gICAgU2VsZWN0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3Qvc2VsZWN0LmpzeCcpLFxuICAgIENoZWNrQm94ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC1jaGVja2JveC9pbnB1dC1jaGVja2JveC5qc3gnKSxcbiAgICBTZWxlY3REYXRhID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3QtZGF0YS9zZWxlY3QtZGF0YS5qc3gnKSxcbiAgICBUZXh0QXJlYSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvdGV4dC1hcmVhL3RleHQtYXJlYS5qc3gnKSxcbiAgICBzdHlsZXMgPSByZXF1aXJlKCcuL3N0eWxlcycpO1xuXG52YXIgTElCUkFSSUVTID0gW3tcbiAgICBpZDogJ3R1bm51cycsIGZpbHRlcjogJydcbn0sIHtcbiAgICBpZDogJ25vbWVuY2xhdHVyZScsXG4gICAgZmlsdGVyOiAnd2hlcmUgZG9rID0gXFwnQVJWXFwnJ1xufSwge1xuICAgIGlkOiAnbGFwc2VfZ3J1cHAnLFxuICAgIGZpbHRlcjogJydcbn1dO1xuXG52YXIgTGFwcyA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhMYXBzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBMYXBzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBMYXBzKTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoTGFwcy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKExhcHMpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMuc3RhdGUgPSB7XG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCksXG4gICAgICAgICAgICBtb2R1bGU6ICdsYXBzZWQnXG4gICAgICAgIH07XG5cbiAgICAgICAgX3RoaXMucmVuZGVyZXIgPSBfdGhpcy5yZW5kZXJlci5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlUGFnZUNsaWNrID0gX3RoaXMuaGFuZGxlUGFnZUNsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2sgPSBfdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmJ0bkVkaXROb21DbGljayA9IF90aGlzLmJ0bkVkaXROb21DbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuYnRuRWRpdExhcHNDbGljayA9IF90aGlzLmJ0bkVkaXRMYXBzQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmJ0bkVkaXRMYXBzZUdydXBwQ2xpY2sgPSBfdGhpcy5idG5FZGl0TGFwc2VHcnVwcENsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5oYW5kbGVJbnB1dENoYW5nZSA9IF90aGlzLmhhbmRsZUlucHV0Q2hhbmdlLmJpbmQoX3RoaXMpO1xuXG4gICAgICAgIF90aGlzLnBhZ2VzID0gW3sgcGFnZU5hbWU6ICdUZWVudXMnLCBkb2NUeXBlSWQ6ICdMQVBTRV9LQUFSVCcgfV07XG5cbiAgICAgICAgX3RoaXMubGlicyA9IHt9OyAvLyBsaWJzIGNhY2hlXG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoTGFwcywgW3tcbiAgICAgICAga2V5OiAnY29tcG9uZW50RGlkTW91bnQnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gY29tcG9uZW50RGlkTW91bnQoKSB7XG4gICAgICAgICAgICB2YXIgbGFwc0lkID0gdm9pZCAwO1xuXG4gICAgICAgICAgICAvL9C10YHQu9C4INC/0LDRgNCw0LzQtdGC0YAg0L3QsCDRgNC10LHQtdC90LrQsCDQt9Cw0LTQsNC9INCyINGB0YLQtdC50YLQtSwg0YLQviDQuNGB0L/QvtC70YzQt9GD0LXQvCDQtdCz0L4uINCY0L3QsNGH0LUg0LjRidC10Lwg0LXQs9C+INCyINC60L7QvdGC0LXQutGB0YLQtVxuICAgICAgICAgICAgaWYgKHRoaXMucHJvcHMuaGlzdG9yeSAmJiB0aGlzLnByb3BzLmhpc3RvcnkubG9jYXRpb24uc3RhdGUpIHtcbiAgICAgICAgICAgICAgICBsYXBzSWQgPSB0aGlzLnByb3BzLmhpc3RvcnkubG9jYXRpb24uc3RhdGUubGFwc0lkO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBsYXBzSWQgPSBEb2NDb250ZXh0WydsYXBzJ10gPyBEb2NDb250ZXh0WydsYXBzJ10gOiBudWxsO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IGxhcHNJZDogbGFwc0lkIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgdmFyIGluaXREYXRhID0gdGhpcy5wcm9wcy5pbml0RGF0YSA/IHRoaXMucHJvcHMuaW5pdERhdGEgOiB7fTtcblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRUZW1wbGF0ZSwgeyBkb2NJZDogdGhpcy5zdGF0ZS5kb2NJZCxcbiAgICAgICAgICAgICAgICByZWY6ICdkb2N1bWVudCcsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnN0YXRlLm1vZHVsZSxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6ICdMQVBTRV9LQUFSVCcsXG4gICAgICAgICAgICAgICAgdXNlckRhdGE6IHRoaXMucHJvcHMudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgaW5pdERhdGE6IGluaXREYXRhLFxuICAgICAgICAgICAgICAgIGxpYnM6IExJQlJBUklFUyxcbiAgICAgICAgICAgICAgICBwYWdlczogdGhpcy5wYWdlcyxcbiAgICAgICAgICAgICAgICByZW5kZXJlcjogdGhpcy5yZW5kZXJlcixcbiAgICAgICAgICAgICAgICBoYW5kbGVHcmlkQnRuQ2xpY2s6IHRoaXMuaGFuZGxlR3JpZEJ0bkNsaWNrLFxuICAgICAgICAgICAgICAgIGhhbmRsZUlucHV0Q2hhbmdlOiB0aGlzLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICBmb2N1c0VsZW1lbnQ6ICdpbnB1dC1rb29kJ1xuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKtCS0LXRgNC90LXRgiDQutCw0YHRgtC+0LzQvdGL0LUg0LrQvtC80L/QvtC90LXQvdGC0Ysg0LTQvtC60YPQvNC10L3RgtCwXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcmVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcmVyKHNlbGYpIHtcbiAgICAgICAgICAgIHZhciBpc0VkaXRNb2RlID0gc2VsZi5zdGF0ZS5lZGl0ZWQ7XG5cbiAgICAgICAgICAgIGlmICgoIU51bWJlcihzZWxmLmRvY0RhdGEuaWQpIHx8ICFzZWxmLmRvY0RhdGEucGFyZW50aWQpICYmIHRoaXMuc3RhdGUubGFwc0lkKSB7XG4gICAgICAgICAgICAgICAgLy9uZXcgcmVjb3JkXG4gICAgICAgICAgICAgICAgc2VsZi5kb2NEYXRhLnBhcmVudGlkID0gdGhpcy5zdGF0ZS5sYXBzSWQ7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHZhciBidXR0b25FZGl0Tm9tID0gc3R5bGVzLmJ0bkVkaXROb207XG5cbiAgICAgICAgICAgIHZhciB5a3N1cyA9IHZvaWQgMDtcbiAgICAgICAgICAgIGlmIChzZWxmLmxpYnNbJ2xhcHNlX2dydXBwJ10gJiYgc2VsZi5kb2NEYXRhLnlrc3VzKSB7XG4gICAgICAgICAgICAgICAgeWtzdXMgPSBzZWxmLmxpYnNbJ2xhcHNlX2dydXBwJ10uZmluZChmdW5jdGlvbiAoeWtzdXMpIHtcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIHlrc3VzLmtvb2QgPT09IHNlbGYuZG9jRGF0YS55a3N1cztcbiAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHZhciBhbGxfeWtzdXNlZCA9ICh5a3N1cyA/IHlrc3VzLmFsbF95a3N1c2VkIDogW10pLm1hcChmdW5jdGlvbiAoaXRlbSwgaW5kZXgpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4geyBpZDogaW5kZXgrKywgbmltZXR1czogaXRlbSB9O1xuICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgIC8vINGE0LjQu9GM0YLRgCDQvdCwINC90L7QvNC10L3QutC70LDRgtGD0YDRi1xuICAgICAgICAgICAgdmFyIG5vbURhdGEgPSBbeyBpZDogMCwga29vZDogJycsIG5pbWV0dXM6ICcnLCBoaW5kOiAwLCBrb2d1czogMCwga2FzX2luZjM6IGZhbHNlIH1dO1xuICAgICAgICAgICAgLy8g0LHQtdGA0LXQvCDRgtC+0LvRjNC60L4g0YPRgdC70YPQs9C4INC00LvRjyDQs9GA0YPQv9C/0YssINC00L7QsdCw0LLQu9GP0Y/QtdC8INGG0LXQvdGDINC4INC10LQu0LjQt9C80LXRgNC10L3QuNGPINC4INGB0L7RgNGC0LjRgNGD0LXQvFxuICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICBpZiAoeWtzdXMpIHtcbiAgICAgICAgICAgICAgICAgICAgbm9tRGF0YSA9ICh5a3N1cy50ZWVudXNlZCAmJiBzZWxmLmxpYnNbJ25vbWVuY2xhdHVyZSddLmxlbmd0aCA+IDAgPyB5a3N1cy50ZWVudXNlZCA6IFtdKS5tYXAoZnVuY3Rpb24gKG5vbSkge1xuICAgICAgICAgICAgICAgICAgICAgICAgdmFyIHJvdyA9IHNlbGYubGlic1snbm9tZW5jbGF0dXJlJ10uZmluZChmdW5jdGlvbiAobGliKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIGxpYi5pZCA9PT0gTnVtYmVyKG5vbS5ub21pZCk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHJvdykge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciB0ZWVudXNlTmltZXR1cyA9IHJvdy5uaW1ldHVzID8gcm93Lm5pbWV0dXMgKyAnIChoaW5kOiAnICsgTnVtYmVyKG5vbS5oaW5kKS50b0ZpeGVkKDIpICsgJykgJyA6ICcnO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBfZXh0ZW5kcyh7fSwgcm93LCB7IG5pbWV0dXM6IHRlZW51c2VOaW1ldHVzLCBpZDogTnVtYmVyKG5vbS5ub21pZCkgfSk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIH0pLnNvcnQoZnVuY3Rpb24gKGEsIGIpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBhLmtvb2QubG9jYWxlQ29tcGFyZShiLmtvb2QpO1xuICAgICAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9IGNhdGNoIChlKSB7XG4gICAgICAgICAgICAgICAgY29uc29sZS5lcnJvcihlLCBub21EYXRhKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvYyB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0RGF0YSwgeyB0aXRsZTogJ0xhcHNlIG5pbWk6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAncGFyZW50aWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHVzZXJEYXRhOiBzZWxmLnVzZXJEYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYk5hbWU6ICdsYXBzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzcWxGaWVsZHM6IFsnbmltaScsICdpc2lrdWtvb2QnXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBbXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnBhcmVudGlkIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVmYXVsdFZhbHVlOiBzZWxmLmRvY0RhdGEubGFwc2VfbmltaSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBib3VuZFRvR3JpZDogJ25pbWknLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJvdW5kVG9EYXRhOiAnbGFwc2VfbmltaScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LXBhcmVudGlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBidG5EZWxldGU6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUgfSlcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChCdXR0b25FZGl0LCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnYnRuRWRpdCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DbGljazogdGhpcy5idG5FZGl0TGFwc0NsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNob3c6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBidXR0b25FZGl0Tm9tLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgICAgICAgICAgICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChTZWxlY3QsIHsgdGl0bGU6ICdcXHhEQ2tzdXM6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAneWtzdXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYnM6ICdsYXBzZV9ncnVwcCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogc2VsZi5saWJzWydsYXBzZV9ncnVwcCddLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEueWtzdXMgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVmYXVsdFZhbHVlOiBzZWxmLmRvY0RhdGEueWtzeXMgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LWxhcHNlX2dydXBwJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xsSWQ6ICdrb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBidG5EZWxldGU6IGlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEJ1dHRvbkVkaXQsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdidG5FZGl0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrOiB0aGlzLmJ0bkVkaXRMYXBzZUdydXBwQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc2hvdzogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBidXR0b25FZGl0Tm9tXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdCwgeyB0aXRsZTogJ0FsbCBcXHhGQ2tzdXM6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYWxsX3lrc3VzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBsaWJzOiAnbGFwc2VfYWxsX3lrc3VzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBhbGxfeWtzdXNlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFsbF95a3N1cyB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHNlbGYuZG9jRGF0YS5hbGxfeWtzeXMgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LWxhcHNlX2FsbF95a3N1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sbElkOiAnbmltZXR1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdCwgeyB0aXRsZTogJ0tvb2Q6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbm9taWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYnM6ICdub21lbmNsYXR1cmUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IG5vbURhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5ub21pZCB8fCAwLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlZmF1bHRWYWx1ZTogc2VsZi5kb2NEYXRhLmtvb2QsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LW5vbWlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xsSWQ6ICdpZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYnRuRGVsZXRlOiBpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEJ1dHRvbkVkaXQsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdidG5FZGl0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrOiB0aGlzLmJ0bkVkaXROb21DbGljayxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzaG93OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGU6IGJ1dHRvbkVkaXROb21cbiAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgcmVmOiAnaW5wdXQtaGluZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdIaW5kOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2hpbmQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIoc2VsZi5kb2NEYXRhLmhpbmQpIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgcmVmOiAnaW5wdXQta29ndXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpdGxlOiAnS29ndXM6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna29ndXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIoc2VsZi5kb2NEYXRhLmtvZ3VzKSB8fCAwLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdCwgeyB0aXRsZTogJ1R1bm51czonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICd0dW5udXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYnM6ICd0dW5udXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHNlbGYubGlic1sndHVubnVzJ10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS50dW5udXMgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVmYXVsdFZhbHVlOiBzZWxmLmRvY0RhdGEudHVubnVzIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3NlbGVjdC10dW5udXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGxJZDogJ2tvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJ0bkRlbGV0ZTogaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGVcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXREYXRlLCB7IHRpdGxlOiAnS2VodGliIGFsYXRlczonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdhbGdfa3B2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFsZ19rcHYgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtYWxnX2twdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXREYXRlLCB7IHRpdGxlOiAnS2VodGliIGt1bmk6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbG9wcF9rcHYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubG9wcF9rcHYgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtbG9wcF9rcHYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KENoZWNrQm94LCB7IHRpdGxlOiAnS2FzIGV0dGVtYWtzPycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2thc19ldHRlbWFrcycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IEJvb2xlYW4oc2VsZi5kb2NEYXRhLmthc19ldHRlbWFrcyksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnY2hlY2tib3hfa2FzX2V0dGVtYWtzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGVcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIHNlbGYuZG9jRGF0YS5rYXNfZXR0ZW1ha3MgPyBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtZXR0ZW1ha3N1X3BlcmlvZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdFdHRlbWFrc3UgcGVyaW9kOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2V0dGVtYWtzdV9wZXJpb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIoc2VsZi5kb2NEYXRhLmV0dGVtYWtzdV9wZXJpb2QpIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApIDogbnVsbFxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChDaGVja0JveCwgeyB0aXRsZTogJ0thcyBhcnZlc3RhIGVyYWxkaT8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrYXNfZXJhbGRpJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogQm9vbGVhbihzZWxmLmRvY0RhdGEua2FzX2VyYWxkaSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnY2hlY2tib3hfa2FzX2VyYWxkaScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQ2hlY2tCb3gsIHsgdGl0bGU6ICdLYXMgSU5GMz8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrYXNfaW5mMycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IEJvb2xlYW4oc2VsZi5kb2NEYXRhLmthc19pbmYzKSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdjaGVja2JveF9rYXNfaW5mMycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtc29vZHVzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aXRsZTogJ1Nvb2R1c3R1czonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdzb29kdXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIoc2VsZi5kb2NEYXRhLnNvb2R1cykgfHwgMCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2VcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dERhdGUsIHsgdGl0bGU6ICdLZWh0aWIgYWxhdGVzOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3Nvb2R1c2VfYWxnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnNvb2R1c2VfYWxnIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXNvb2R1c19hbGcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXREYXRlLCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdLZWh0aWIga3VuaTonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdzb29kdXNlX2xvcHAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuc29vZHVzZV9sb3BwIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXNvb2R1c19sb3BwJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2VcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChDaGVja0JveCwgeyB0aXRsZTogJ0thcyBzb29kdXN0dXMgcHJvdHNlbnRpZGVzPycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2thc19wcm90c2VudCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IEJvb2xlYW4oc2VsZi5kb2NEYXRhLmthc19wcm90c2VudCksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnY2hlY2tib3hfa2FzX3Byb3RzZW50JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGVcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdNXFx4RTRya3VzZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ211dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubXV1ZCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVBhZ2VDbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVQYWdlQ2xpY2socGFnZURvY1R5cGVJZCkge1xuICAgICAgICAgICAgLy8gICAgICAgIGRvY3VtZW50LmxvY2F0aW9uLmhyZWYgPSBgL2xhcHNlZC8ke3BhZ2VEb2NUeXBlSWR9L2A7Ly9AdG9kbyDQntCx0L3QvtCy0LjRgtGMXG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC8nICsgcGFnZURvY1R5cGVJZCk7XG4gICAgICAgIH1cblxuICAgICAgICAvL2hhbmRsZXIgZm9yIGlucHV0IGZvciB0aGlzIGRvY3VtZW50IHR5cGVcblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnaGFuZGxlSW5wdXRDaGFuZ2UnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaGFuZGxlSW5wdXRDaGFuZ2UoaW5wdXROYW1lLCBpbnB1dFZhbHVlKSB7XG5cbiAgICAgICAgICAgIGlmIChpbnB1dE5hbWUgPT09ICdub21pZCcpIHtcbiAgICAgICAgICAgICAgICB2YXIgRG9jID0gdGhpcy5yZWZzWydkb2N1bWVudCddO1xuXG4gICAgICAgICAgICAgICAgLy8g0L3QsNC00L4g0LfQsNC00LDRgtGMINGG0LXQvdGDINC4INC60L7Quy3QstC+INC40Lcg0YLQvtCz0L4sINGH0YLQviDQv9GA0LjQstGP0LfQsNC90L3QviDQsiDQs9GA0YPQv9C/0LVcblxuICAgICAgICAgICAgICAgIHZhciB5a3N1cyA9IHZvaWQgMDtcbiAgICAgICAgICAgICAgICBpZiAoRG9jLmxpYnNbJ2xhcHNlX2dydXBwJ10gJiYgRG9jLmRvY0RhdGEueWtzdXMpIHtcbiAgICAgICAgICAgICAgICAgICAgeWtzdXMgPSBEb2MubGlic1snbGFwc2VfZ3J1cHAnXS5maW5kKGZ1bmN0aW9uIChvYmopIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBvYmoua29vZCA9PT0gRG9jLmRvY0RhdGEueWtzdXM7XG4gICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgIGlmICh5a3N1cy50ZWVudXNlZCkge1xuICAgICAgICAgICAgICAgICAgICB2YXIgdGVlbnVzID0geWtzdXMudGVlbnVzZWQuZmluZChmdW5jdGlvbiAob2JqKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gb2JqLm5vbWlkID09IGlucHV0VmFsdWU7XG4gICAgICAgICAgICAgICAgICAgIH0pO1xuXG4gICAgICAgICAgICAgICAgICAgIERvYy5kb2NEYXRhLmtvZ3VzID0gdGVlbnVzLmtvZ3VzID8gdGVlbnVzLmtvZ3VzIDogRG9jLmRvY0RhdGEua29ndXM7XG4gICAgICAgICAgICAgICAgICAgIERvYy5kb2NEYXRhLmhpbmQgPSB0ZWVudXMuaGluZCA/IHRlZW51cy5oaW5kIDogRG9jLmRvY0RhdGEuaGluZDtcbiAgICAgICAgICAgICAgICAgICAgLy8g0L/QvtC00LzQtdC90LjQvCDQvdC+0LzQuNC0INC90LAg0LjQtCwg0YLQsNC6INC60LDQuiDQuNC0INCy0LjRgNGC0YPQsNC70YzQvdGL0LlcbiAgICAgICAgICAgICAgICAgICAgRG9jLmRvY0RhdGEubm9taWQgPSB0ZWVudXMubm9taWQgPyB0ZWVudXMubm9taWQgOiBEb2MuZG9jRGF0YS5ub21pZDtcblxuICAgICAgICAgICAgICAgICAgICAvLyDQtdGB0LvQuCDRjdGC0L4g0YHQvtC30LTQsNC90LjQtSDQutCw0YDRgtC+0YfQutC4LCDRgtC+INC00L7QsdCw0LLQuNC8IGluZjNcbiAgICAgICAgICAgICAgICAgICAgdmFyIGlzX25ldyA9ICEoJ2lkJyBpbiBEb2MuZG9jRGF0YSkgfHwgIURvYy5kb2NEYXRhLmlkID8gdHJ1ZSA6IGZhbHNlO1xuXG4gICAgICAgICAgICAgICAgICAgIGlmIChpc19uZXcpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhciByb3cgPSBEb2MubGlic1snbm9tZW5jbGF0dXJlJ10uZmluZChmdW5jdGlvbiAobGliKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIGxpYi5pZCA9PT0gTnVtYmVyKERvYy5kb2NEYXRhLm5vbWlkKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHJvdyAmJiByb3cua2FzX2luZjMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBEb2MuZG9jRGF0YS5rYXNfaW5mMyA9IHJvdy5rYXNfaW5mMztcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIC8vINC+0LHRgNCw0LHQvtGC0YfQuNC6INGB0L7QsdGL0YLQuNGPINC60LvQuNC6INC90LAg0LPRgNC40LTQtSDRgNC+0LTQuNGC0LXQu9C10LlcblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnaGFuZGxlR3JpZEJ0bkNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZUdyaWRCdG5DbGljayhidG5OYW1lLCBhY3RpdmVSb3csIGlkLCBkb2NUeXBlSWQpIHtcbiAgICAgICAgICAgIHN3aXRjaCAoYnRuTmFtZSkge1xuICAgICAgICAgICAgICAgIGNhc2UgXCJlZGl0XCI6XG4gICAgICAgICAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKCcvbGFwc2VkLycgKyBkb2NUeXBlSWQgKyAnLycgKyBpZCk7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIGNhc2UgXCJhZGRcIjpcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goJy9sYXBzZWQvJyArIGRvY1R5cGVJZCArICcvMC8nICsgdGhpcy5zdGF0ZS5kb2NJZCk7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIGNhc2UgXCJkZWxldGVcIjpcbiAgICAgICAgICAgICAgICAgICAgY29uc29sZS5sb2coJ2J0bkRlbGV0ZSBjbGlja2VkJyk7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIGRlZmF1bHQ6XG4gICAgICAgICAgICAgICAgICAgIGNvbnNvbGUubG9nKCdWaWdhbmUgY2xpY2snKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIC8v0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0L/QviDQutC70LjQutGDINC60L3QvtC/0LrQuCDQoNC10LTQsNC60YLQuNGA0L7QstCw0L3QuNC1INGB0L3QvtC80LXQvdC60LvQsNGC0YPRgNGLXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2J0bkVkaXROb21DbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBidG5FZGl0Tm9tQ2xpY2soKSB7XG4gICAgICAgICAgICB2YXIgZG9jTm9tSWQgPSB0aGlzLnJlZnNbJ2RvY3VtZW50J10uZG9jRGF0YS5ub21pZDtcblxuICAgICAgICAgICAgLy8g0L7RgdGD0YnQtdGB0YLQstC40YIg0L/QtdGA0LXRhdC+0LQg0L3QsCDQutCw0YDRgtC+0YfQutGDINC60L7QvdGC0YAt0LDQs9C10L3RgtCwXG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC9ub21lbmNsYXR1cmUvJyArIGRvY05vbUlkKTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnYnRuRWRpdExhcHNlR3J1cHBDbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBidG5FZGl0TGFwc2VHcnVwcENsaWNrKCkge1xuICAgICAgICAgICAgdmFyIGRvY0xhcHNlR3J1cHBLb29kID0gdGhpcy5yZWZzWydkb2N1bWVudCddLmRvY0RhdGEueWtzdXM7XG4gICAgICAgICAgICAvLyDQuNGJ0LXQvCDQuNC0XG5cbiAgICAgICAgICAgIHZhciBsYXBzZUdydXBwSWQgPSB0aGlzLnJlZnNbJ2RvY3VtZW50J10ubGlic1snbGFwc2VfZ3J1cHAnXS5maW5kKGZ1bmN0aW9uIChyb3cpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gcm93Lmtvb2QgPT09IGRvY0xhcHNlR3J1cHBLb29kO1xuICAgICAgICAgICAgfSkuaWQ7XG5cbiAgICAgICAgICAgIGlmIChsYXBzZUdydXBwSWQpIHtcbiAgICAgICAgICAgICAgICAvLyDQvtGB0YPRidC10YHRgtCy0LjRgiDQv9C10YDQtdGF0L7QtCDQvdCwINC60LDRgNGC0L7Rh9C60YMg0LrQvtC90YLRgC3QsNCz0LXQvdGC0LBcbiAgICAgICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC9sYXBzZV9ncnVwcC8nICsgbGFwc2VHcnVwcElkKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIC8v0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0L/QviDQutC70LjQutGDINC60L3QvtC/0LrQuCDQoNC10LTQsNC60YLQuNGA0L7QstCw0L3QuNC1INGA0LXQsdC10L3QutCwXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2J0bkVkaXRMYXBzQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gYnRuRWRpdExhcHNDbGljaygpIHtcbiAgICAgICAgICAgIHZhciBkb2NMYXBzSWQgPSB0aGlzLnJlZnNbJ2RvY3VtZW50J10uZG9jRGF0YS5wYXJlbnRpZDtcblxuICAgICAgICAgICAgLy8g0L7RgdGD0YnQtdGB0YLQstC40YIg0L/QtdGA0LXRhdC+0LQg0L3QsCDQutCw0YDRgtC+0YfQutGDINC60L7QvdGC0YAt0LDQs9C10L3RgtCwXG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCh7XG4gICAgICAgICAgICAgICAgcGF0aG5hbWU6ICcvbGFwc2VkL2xhcHMvJyArIGRvY0xhcHNJZCxcbiAgICAgICAgICAgICAgICBzdGF0ZTogeyB0ZWVudXNJZDogdGhpcy5zdGF0ZS5kb2NJZCwgbW9kdWxlOiB0aGlzLnN0YXRlLm1vZHVsZSB9XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBMYXBzO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuTGFwcy5wcm9wVHlwZXMgPSB7XG4gICAgZG9jSWQ6IFByb3BUeXBlcy5udW1iZXIsXG4gICAgaW5pdERhdGE6IFByb3BUeXBlcy5vYmplY3QsXG4gICAgdXNlckRhdGE6IFByb3BUeXBlcy5vYmplY3Rcbn07XG5cbkxhcHMuZGVmYXVsdFByb3BzID0ge1xuICAgIHBhcmFtczogeyBkb2NJZDogMCB9LFxuICAgIGluaXREYXRhOiB7fSxcbiAgICB1c2VyRGF0YToge31cbn07XG5cbm1vZHVsZS5leHBvcnRzID0gTGFwcztcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvbGFwc2Vfa2FhcnQvZG9jdW1lbnQvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyMzZcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBkb2NSb3c6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAncm93J1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsdWUnXHJcbiAgICAgICAgKi9cbiAgICB9LFxuICAgIGRvY0NvbHVtbjoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nLFxuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIHllbGxvdycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgd2lkdGg6ICc1MCUnXG4gICAgfSxcbiAgICBkb2M6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJ1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJyb3duJ1xyXG4gICAgICAgICovXG4gICAgfSxcblxuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9LFxuXG4gICAgZ3JpZFJvdzoge1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsYWNrJyxcclxuICAgICAgICAqL1xuICAgICAgICBiYWNrZ3JvdW5kQ29sb3I6ICd3aGl0ZScsXG4gICAgICAgIHBvc2l0aW9uOiAncmVsYXRpdmUnLFxuICAgICAgICBtYXJnaW46ICcxMCUgMzAlIDEwJSAzMCUnLFxuICAgICAgICB3aWR0aDogJ2F1dG8nLFxuICAgICAgICBvcGFjaXR5OiAnMScsXG4gICAgICAgIHRvcDogJzEwMHB4J1xuICAgIH0sXG5cbiAgICBidG5FZGl0Tm9tOiB7XG4gICAgICAgIHdpZHRoOiAnbWluLWNvbnRlbnQnXG4gICAgfSxcblxuICAgIHNlbGVjdE5vbToge1xuICAgICAgICBtYXJnaW5MZWZ0OiAnMTBweCdcbiAgICB9XG5cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHNlX2thYXJ0L2RvY3VtZW50L3N0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjQxXG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIERvY3VtZW50UmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3VtZW50cy9kb2N1bWVudHMuanN4Jyk7XG52YXIgSW5wdXROdW1iZXIgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2lucHV0LW51bWJlci9pbnB1dC1udW1iZXIuanN4Jyk7XG52YXIgZ2V0U3VtID0gcmVxdWlyZSgnLi8uLi8uLi8uLi9saWJzL2dldFN1bScpO1xuXG52YXIgc3R5bGVzID0gcmVxdWlyZSgnLi9zdHlsZXMnKTtcbnZhciBET0NfVFlQRV9JRCA9ICdMQVBTRV9UQUFCRUwnO1xuXG4vKipcclxuICog0JrQu9Cw0YHRgSDRgNC10LDQu9C40LfRg9C10YIg0LTQvtC60YPQvNC10L3RgiDRgdC/0YDQsNCy0L7Rh9C90LjQutCwINC/0YDQuNC30L3QsNC60L7Qsi5cclxuICovXG5cbnZhciBEb2N1bWVudHMgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoRG9jdW1lbnRzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBEb2N1bWVudHMocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIERvY3VtZW50cyk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKERvY3VtZW50cy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKERvY3VtZW50cykpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIHN1bW1hOiAwXG4gICAgICAgIH07XG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG5cbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2N1bWVudHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRSZWdpc3RlciwgeyBpbml0RGF0YTogdGhpcy5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnByb3BzLm1vZHVsZSxcbiAgICAgICAgICAgICAgICAgICAgcmVmOiAncmVnaXN0ZXInLFxuICAgICAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6IERPQ19UWVBFX0lELFxuICAgICAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IHRoaXMucmVuZGVyZXIgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dE51bWJlciwgeyB0aXRsZTogJ1N1bW1hIGtva2t1OicsXG4gICAgICAgICAgICAgICAgICAgIG5hbWU6ICdzdW1tYV9rb2trdScsXG4gICAgICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMudG90YWwsXG4gICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXN1bW1hJyxcbiAgICAgICAgICAgICAgICAgICAgdmFsdWU6IE51bWJlcih0aGlzLnN0YXRlLnN1bW1hKS50b0ZpeGVkKDIpIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlXG5cbiAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8vIGN1c3RvbSByZW5kZXJcblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgdmFyIHN1bW1hID0gZ2V0U3VtKHNlbGYuZ3JpZERhdGEgfHwgW10sICdzdW1tYScpO1xuICAgICAgICAgICAgaWYgKHN1bW1hKSB7XG4gICAgICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IHN1bW1hOiBzdW1tYSB9KTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgJ0xhcHNlIHRhYWJlbCByZWdpc3RlciBzcGVjaWFsIHJlbmRlcidcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gRG9jdW1lbnRzO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxubW9kdWxlLmV4cG9ydHMgPSBEb2N1bWVudHM7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2xhcHNlX3RhYWJlbC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDI0MlxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCJcInVzZSBzdHJpY3RcIjtcblxuLy8gd2lsbCBjYWxjdWxhdGUgc3VtIG9mIHNvbWUgZmllbGRcbnZhciBnZXRTdW0gPSBmdW5jdGlvbiBnZXRTdW0oZGF0YSwgY29sdW1uRmllbGQpIHtcblxuICAgIHZhciB0b3RhbCA9IDA7XG4gICAgaWYgKGRhdGEgJiYgZGF0YS5sZW5ndGggJiYgZGF0YVswXVtjb2x1bW5GaWVsZF0pIHtcbiAgICAgICAgZGF0YS5mb3JFYWNoKGZ1bmN0aW9uIChyb3cpIHtcbiAgICAgICAgICAgIHJldHVybiB0b3RhbCA9IHRvdGFsICsgTnVtYmVyKHJvd1tjb2x1bW5GaWVsZF0pO1xuICAgICAgICB9KTtcbiAgICB9XG5cbiAgICByZXR1cm4gdG90YWwudG9GaXhlZCgyKTtcbn07XG5tb2R1bGUuZXhwb3J0cyA9IGdldFN1bTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2xpYnMvZ2V0U3VtLmpzXG4vLyBtb2R1bGUgaWQgPSAyNDNcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBncmlkOiB7XG4gICAgICAgIG1haW5UYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuICAgICAgICBoZWFkZXJUYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuXG4gICAgICAgIGdyaWRDb250YWluZXI6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnOTUlJ1xuICAgICAgICB9XG5cbiAgICB9LFxuICAgIHRvdGFsOiB7XG4gICAgICAgIHdpZHRoOiAnYXV0bydcbiAgICB9XG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzZV90YWFiZWwvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyNDRcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBQcm9wVHlwZXMgPSByZXF1aXJlKCdwcm9wLXR5cGVzJyk7XG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xuXG52YXIgRG9jdW1lbnRUZW1wbGF0ZSA9IHJlcXVpcmUoJy4uLy4uL2RvY3VtZW50VGVtcGxhdGUvaW5kZXguanN4JyksXG4gICAgSW5wdXROdW1iZXIgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LW51bWJlci9pbnB1dC1udW1iZXIuanN4JyksXG4gICAgQnV0dG9uRWRpdCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi1yZWdpc3Rlci1lZGl0L2J1dHRvbi1yZWdpc3Rlci1lZGl0LmpzeCcpLFxuICAgIFNlbGVjdCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvc2VsZWN0L3NlbGVjdC5qc3gnKSxcbiAgICBTZWxlY3REYXRhID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3QtZGF0YS9zZWxlY3QtZGF0YS5qc3gnKSxcbiAgICBUZXh0QXJlYSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvdGV4dC1hcmVhL3RleHQtYXJlYS5qc3gnKSxcbiAgICBzdHlsZXMgPSByZXF1aXJlKCcuL3N0eWxlcycpO1xuXG52YXIgRG9jQ29udGV4dCA9IHJlcXVpcmUoJy4uLy4uLy4uL2RvYy1jb250ZXh0Jyk7XG5cbnZhciBMYXBzID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKExhcHMsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIExhcHMocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIExhcHMpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChMYXBzLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoTGFwcykpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIG1vZHVsZTogJ2xhcHNlZCcsXG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCksXG4gICAgICAgICAgICBsYXBzSWQ6IHByb3BzLmxhcHNJZCA/IHByb3BzLmxhcHNJZCA6IHByb3BzLm1hdGNoLnBhcmFtcy5wYXJhbUlkID8gTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5wYXJhbUlkKSA6IDBcbiAgICAgICAgfTtcblxuICAgICAgICBfdGhpcy5yZW5kZXJlciA9IF90aGlzLnJlbmRlcmVyLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5oYW5kbGVQYWdlQ2xpY2sgPSBfdGhpcy5oYW5kbGVQYWdlQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmhhbmRsZUdyaWRCdG5DbGljayA9IF90aGlzLmhhbmRsZUdyaWRCdG5DbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuYnRuRWRpdE5vbUNsaWNrID0gX3RoaXMuYnRuRWRpdE5vbUNsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5idG5FZGl0TGFwc0NsaWNrID0gX3RoaXMuYnRuRWRpdExhcHNDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMubGFwc0lkQ2hhbmdlaGFuZGxlciA9IF90aGlzLmxhcHNJZENoYW5nZWhhbmRsZXIuYmluZChfdGhpcyk7XG5cbiAgICAgICAgX3RoaXMucGFnZXMgPSBbeyBwYWdlTmFtZTogJ0xhcHNlIHRhYWJlbCcsIGRvY1R5cGVJZDogJ0xBUFNFX1RBQUJFTCcgfV07XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoTGFwcywgW3tcbiAgICAgICAga2V5OiAnY29tcG9uZW50RGlkTW91bnQnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gY29tcG9uZW50RGlkTW91bnQoKSB7XG4gICAgICAgICAgICBpZiAoIXRoaXMuc3RhdGUubGFwc0lkICYmIERvY0NvbnRleHRbJ2xhcHMnXSkge1xuICAgICAgICAgICAgICAgIC8v0LXRgdGC0Ywg0LfQvdCw0YfQtdC90LjQtSDQuNC0INGA0LXQsdC10L3QutCwXG4gICAgICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IGxhcHNJZDogRG9jQ29udGV4dFsnbGFwcyddIH0pO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdjb21wb25lbnREaWRVcGRhdGUnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gY29tcG9uZW50RGlkVXBkYXRlKHByZXZQcm9wcywgcHJldlN0YXRlKSB7XG4gICAgICAgICAgICAvLyDQvtCx0L3QvtCy0LjQvCDRgdC/0YDQsNCy0L7Rh9C90LjQutC4INGA0LXQsdC10L3QutCwXG4gICAgICAgICAgICBpZiAodGhpcy5zdGF0ZS5sYXBzSWQgIT09IHByZXZTdGF0ZS5sYXBzSWQpIHtcbiAgICAgICAgICAgICAgICB2YXIgZG9jID0gdGhpcy5yZWZzWydkb2N1bWVudCddO1xuICAgICAgICAgICAgICAgIGRvYy5jcmVhdGVMaWJzKCk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICB2YXIgZmlsdGVyID0gdGhpcy5zdGF0ZS5sYXBzSWQgPyAnd2hlcmUgbGFwc2lkID0gJyArIHRoaXMuc3RhdGUubGFwc0lkIDogJyc7XG5cbiAgICAgICAgICAgIHZhciBMSUJSQVJJRVMgPSBbeyBpZDogJ2xhcHNlX2thYXJ0JywgZmlsdGVyOiBmaWx0ZXIgfV07XG5cbiAgICAgICAgICAgIHZhciBpbml0RGF0YSA9IHRoaXMucHJvcHMuaW5pdERhdGEgPyB0aGlzLnByb3BzLmluaXREYXRhIDoge307XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50VGVtcGxhdGUsIHsgZG9jSWQ6IHRoaXMuc3RhdGUuZG9jSWQsXG4gICAgICAgICAgICAgICAgcmVmOiAnZG9jdW1lbnQnLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ0xBUFNFX1RBQUJFTCcsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnN0YXRlLm1vZHVsZSxcbiAgICAgICAgICAgICAgICBpbml0RGF0YTogaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgbGliczogTElCUkFSSUVTLFxuICAgICAgICAgICAgICAgIHBhZ2VzOiB0aGlzLnBhZ2VzLFxuICAgICAgICAgICAgICAgIHJlbmRlcmVyOiB0aGlzLnJlbmRlcmVyLFxuICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2ssXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5LFxuICAgICAgICAgICAgICAgIGZvY3VzRWxlbWVudDogJ2lucHV0LWtvb2QnXG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAq0JLQtdGA0L3QtdGCINC60LDRgdGC0L7QvNC90YvQtSDQutC+0LzQv9C+0L3QtdC90YLRiyDQtNC+0LrRg9C80LXQvdGC0LBcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgdmFyIGlzRWRpdE1vZGUgPSBzZWxmLnN0YXRlLmVkaXRlZDtcblxuICAgICAgICAgICAgaWYgKChzZWxmLmRvY0RhdGEuaWQgPT09IDAgfHwgIXNlbGYuZG9jRGF0YS5wYXJlbnRpZCkgJiYgdGhpcy5zdGF0ZS5sYXBzSWQpIHtcbiAgICAgICAgICAgICAgICAvL25ldyByZWNvcmRcbiAgICAgICAgICAgICAgICBzZWxmLmRvY0RhdGEucGFyZW50aWQgPSB0aGlzLnN0YXRlLmxhcHNJZDtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgaWYgKCF0aGlzLnN0YXRlLmxhcHNJZCAmJiBzZWxmLmRvY0RhdGEucGFyZW50aWQpIHtcbiAgICAgICAgICAgICAgICB0aGlzLnNldFN0YXRlKHsgbGFwc0lkOiBzZWxmLmRvY0RhdGEucGFyZW50aWQgfSk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHZhciBrcHYgPSBuZXcgRGF0ZSgpLFxuICAgICAgICAgICAgICAgIGt1dSA9IGtwdi5nZXRNb250aCgpLFxuICAgICAgICAgICAgICAgIGFhc3RhID0ga3B2LmdldEZ1bGxZZWFyKCk7XG5cbiAgICAgICAgICAgIHZhciBidXR0b25FZGl0Tm9tID0gc3R5bGVzLmJ0bkVkaXROb207XG5cbiAgICAgICAgICAgIC8v0YTQuNC70YzRgtGAINC90LAg0LjRgdC/0L7Qu9GM0LfRg9C10LzRiyDQvdC+0LzQtdC90LrQu9Cw0YLRg9GA0YtcbiAgICAgICAgICAgIHZhciBub21EYXRhID0gc2VsZi5saWJzWydsYXBzZV9rYWFydCddID8gc2VsZi5saWJzWydsYXBzZV9rYWFydCddLmZpbHRlcihmdW5jdGlvbiAocm93KSB7XG4gICAgICAgICAgICAgICAgcmV0dXJuIHJvdy5sYXBzaWQgPT09IHNlbGYuZG9jRGF0YS5wYXJlbnRpZDtcbiAgICAgICAgICAgIH0pIDogW107XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2MgfSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdERhdGEsIHsgdGl0bGU6ICdMYXBzZSBuaW1pOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3BhcmVudGlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBsaWJOYW1lOiAnbGFwcycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc3FsRmllbGRzOiBbJ25pbWknLCAnaXNpa3Vrb29kJ10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogW10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5wYXJlbnRpZCB8fCAwLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlZmF1bHRWYWx1ZTogc2VsZi5kb2NEYXRhLm5pbWksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYm91bmRUb0dyaWQ6ICduaW1pJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBib3VuZFRvRGF0YTogJ25pbWknLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3NlbGVjdC1wYXJlbnRpZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYnRuRGVsZXRlOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB1c2VyRGF0YTogc2VsZi51c2VyRGF0YSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5sYXBzSWRDaGFuZ2VoYW5kbGVyLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEJ1dHRvbkVkaXQsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdidG5FZGl0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrOiB0aGlzLmJ0bkVkaXRMYXBzQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc2hvdzogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGU6IGJ1dHRvbkVkaXROb20sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdCwgeyB0aXRsZTogJ0tvb2Q6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbGFwc2Vfa2FhcnRfaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYnM6ICdsYXBzZV9rYWFydCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogbm9tRGF0YSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmxhcHNlX2thYXJ0X2lkIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVmYXVsdFZhbHVlOiBzZWxmLmRvY0RhdGEubmltZXR1cyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdzZWxlY3QtbGFwc2Vfa2FhcnRfaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJ0bkRlbGV0ZTogaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUgfSlcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChCdXR0b25FZGl0LCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnYnRuRWRpdCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DbGljazogdGhpcy5idG5FZGl0Tm9tQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc2hvdzogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGU6IGJ1dHRvbkVkaXROb20sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7IHJlZjogJ2lucHV0LWtvZ3VzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aXRsZTogJ0tvZ3VzOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2tvZ3VzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHNlbGYuZG9jRGF0YS5rb2d1cykgfHwgTnVtYmVyKG51bGwpLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgcmVmOiAnaW5wdXQta3V1JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aXRsZTogJ0t1dTonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrdXUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIoc2VsZi5kb2NEYXRhLmt1dSkgfHwgTnVtYmVyKGt1dSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dE51bWJlciwgeyByZWY6ICdpbnB1dC1hYXN0YScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdBYXN0YTonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdhYXN0YScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IE51bWJlcihzZWxmLmRvY0RhdGEuYWFzdGEpIHx8IE51bWJlcihhYXN0YSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdNXFx4RTRya3VzZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ211dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubXV1ZCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVBhZ2VDbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVQYWdlQ2xpY2socGFnZURvY1R5cGVJZCkge1xuICAgICAgICAgICAgLy8gICAgICAgIGRvY3VtZW50LmxvY2F0aW9uLmhyZWYgPSBgL2xhcHNlZC8ke3BhZ2VEb2NUeXBlSWR9L2A7Ly9AdG9kbyDQntCx0L3QvtCy0LjRgtGMXG4gICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC8nICsgcGFnZURvY1R5cGVJZCk7XG4gICAgICAgIH1cblxuICAgICAgICAvLyDQvtCx0YDQsNCx0L7RgtGH0LjQuiDRgdC+0LHRi9GC0LjRjyDQutC70LjQuiDQvdCwINCz0YDQuNC00LUg0YDQvtC00LjRgtC10LvQtdC5XG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZUdyaWRCdG5DbGljaycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBoYW5kbGVHcmlkQnRuQ2xpY2soYnRuTmFtZSwgYWN0aXZlUm93LCBpZCwgZG9jVHlwZUlkKSB7XG4gICAgICAgICAgICBzd2l0Y2ggKGJ0bk5hbWUpIHtcbiAgICAgICAgICAgICAgICBjYXNlIFwiZWRpdFwiOlxuICAgICAgICAgICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC8nICsgZG9jVHlwZUlkICsgJy8nICsgaWQgKyAnLzAnKTtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgY2FzZSBcImFkZFwiOlxuICAgICAgICAgICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCgnL2xhcHNlZC8nICsgZG9jVHlwZUlkICsgJy8wLycgKyB0aGlzLnN0YXRlLmRvY0lkKTtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgZGVmYXVsdDpcbiAgICAgICAgICAgICAgICAgICAgY29uc29sZS5sb2coJ1ZpZ2FuZSBjbGljaycpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgLy/QvtCx0YDQsNCx0L7RgtGH0LjQuiDRgdC+0LHRi9GC0LjRjyDQv9C+INC60LvQuNC60YMg0LrQvdC+0L/QutC4INCg0LXQtNCw0LrRgtC40YDQvtCy0LDQvdC40LUg0YHQvdC+0LzQtdC90LrQu9Cw0YLRg9GA0YtcblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnYnRuRWRpdE5vbUNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGJ0bkVkaXROb21DbGljaygpIHtcbiAgICAgICAgICAgIHZhciBkb2NJZCA9IHRoaXMucmVmc1snZG9jdW1lbnQnXS5kb2NEYXRhLmxhcHNlX2thYXJ0X2lkO1xuXG4gICAgICAgICAgICAvLyDQvtGB0YPRidC10YHRgtCy0LjRgiDQv9C10YDQtdGF0L7QtCDQvdCwINC60LDRgNGC0L7Rh9C60YMg0LrQvtC90YLRgC3QsNCz0LXQvdGC0LBcbiAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKCcvbGFwc2VkL2xhcHNlX2thYXJ0LycgKyBkb2NJZCk7XG4gICAgICAgIH1cblxuICAgICAgICAvL9C+0LHRgNCw0LHQvtGC0YfQuNC6INGB0L7QsdGL0YLQuNGPINC/0L4g0LrQu9C40LrRgyDQutC90L7Qv9C60Lgg0KDQtdC00LDQutGC0LjRgNC+0LLQsNC90LjQtSDRgNC10LHQtdC90LrQsFxuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdidG5FZGl0TGFwc0NsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGJ0bkVkaXRMYXBzQ2xpY2soKSB7XG4gICAgICAgICAgICB2YXIgZG9jTGFwc0lkID0gdGhpcy5yZWZzWydkb2N1bWVudCddLmRvY0RhdGEucGFyZW50aWQ7XG5cbiAgICAgICAgICAgIC8vINC+0YHRg9GJ0LXRgdGC0LLQuNGCINC/0LXRgNC10YXQvtC0INC90LAg0LrQsNGA0YLQvtGH0LrRgyDQutC+0L3RgtGALdCw0LPQtdC90YLQsFxuICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goJy9sYXBzZWQvbGFwcy8nICsgZG9jTGFwc0lkKTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnbGFwc0lkQ2hhbmdlaGFuZGxlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBsYXBzSWRDaGFuZ2VoYW5kbGVyKGlucHV0TmFtZSwgaW5wdXRWYWx1ZSkge1xuICAgICAgICAgICAgdmFyIERvYyA9IHRoaXMucmVmc1snZG9jdW1lbnQnXTtcblxuICAgICAgICAgICAgLy8g0L7RgtC00LDRgtGMINC30L3QsNGH0LXQvdC40LUg0LTQvtC60YPQvNC10L3RgtGDXG4gICAgICAgICAgICBEb2MuaGFuZGxlSW5wdXRDaGFuZ2UoaW5wdXROYW1lLCBpbnB1dFZhbHVlKTtcblxuICAgICAgICAgICAgLy8g0L7QsdC90L7QstC40YLRjCDRgdC/0YDQsNCy0L7Rh9C90LjQulxuICAgICAgICAgICAgRG9jLmNyZWF0ZUxpYnMoKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBMYXBzO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuTGFwcy5wcm9wVHlwZXMgPSB7XG4gICAgZG9jSWQ6IFByb3BUeXBlcy5udW1iZXIsXG4gICAgaW5pdERhdGE6IFByb3BUeXBlcy5vYmplY3QsXG4gICAgdXNlckRhdGE6IFByb3BUeXBlcy5vYmplY3Rcbn07XG5cbkxhcHMuZGVmYXVsdFByb3BzID0ge1xuICAgIHBhcmFtczogeyBkb2NJZDogMCB9LFxuICAgIGluaXREYXRhOiB7fSxcbiAgICB1c2VyRGF0YToge31cbn07XG5cbm1vZHVsZS5leHBvcnRzID0gTGFwcztcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvbGFwc2VfdGFhYmVsL2RvY3VtZW50L2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMjQ1XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgZG9jUm93OiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ3JvdydcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBibHVlJ1xyXG4gICAgICAgICovXG4gICAgfSxcbiAgICBkb2NDb2x1bW46IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJyxcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCB5ZWxsb3cnLFxyXG4gICAgICAgICovXG4gICAgICAgIHdpZHRoOiAnNTAlJ1xuICAgIH0sXG4gICAgZG9jOiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ2NvbHVtbidcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBicm93bidcclxuICAgICAgICAqL1xuICAgIH0sXG5cbiAgICBncmlkOiB7XG4gICAgICAgIG1haW5UYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuICAgICAgICBoZWFkZXJUYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuXG4gICAgICAgIGdyaWRDb250YWluZXI6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfVxuXG4gICAgfSxcblxuICAgIGdyaWRSb3c6IHtcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBibGFjaycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgYmFja2dyb3VuZENvbG9yOiAnd2hpdGUnLFxuICAgICAgICBwb3NpdGlvbjogJ3JlbGF0aXZlJyxcbiAgICAgICAgbWFyZ2luOiAnMTAlIDMwJSAxMCUgMzAlJyxcbiAgICAgICAgd2lkdGg6ICdhdXRvJyxcbiAgICAgICAgb3BhY2l0eTogJzEnLFxuICAgICAgICB0b3A6ICcxMDBweCdcbiAgICB9LFxuXG4gICAgYnRuRWRpdE5vbToge1xuICAgICAgICB3aWR0aDogJ21pbi1jb250ZW50J1xuICAgIH1cblxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvbGFwc2VfdGFhYmVsL2RvY3VtZW50L3N0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjQ2XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcblxudmFyIERvY3VtZW50VGVtcGxhdGUgPSByZXF1aXJlKCcuLi8uLi9kb2N1bWVudFRlbXBsYXRlL2luZGV4LmpzeCcpLFxuICAgIElucHV0VGV4dCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtdGV4dC9pbnB1dC10ZXh0LmpzeCcpLFxuICAgIFNlbGVjdCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvc2VsZWN0L3NlbGVjdC5qc3gnKSxcbiAgICBCdXR0b25FZGl0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9idXR0b24tcmVnaXN0ZXIvYnV0dG9uLXJlZ2lzdGVyLWVkaXQvYnV0dG9uLXJlZ2lzdGVyLWVkaXQuanN4JyksXG4gICAgU2VsZWN0RGF0YSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvc2VsZWN0LWRhdGEvc2VsZWN0LWRhdGEuanN4JyksXG4gICAgVGV4dEFyZWEgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL3RleHQtYXJlYS90ZXh0LWFyZWEuanN4JyksXG4gICAgRGF0YUdyaWQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2RhdGEtZ3JpZC9kYXRhLWdyaWQuanN4JyksXG4gICAgQ2hlY2tCb3ggPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LWNoZWNrYm94L2lucHV0LWNoZWNrYm94LmpzeCcpLFxuICAgIHN0eWxlcyA9IHJlcXVpcmUoJy4vc3R5bGVzJyk7XG5cbnZhciBMSUJET0sgPSAnVkFORU0nLFxuICAgIExJQlJBUklFUyA9IFtdO1xuXG52YXIgbm93ID0gbmV3IERhdGUoKTtcblxudmFyIFZhbmVtID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKFZhbmVtLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBWYW5lbShwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgVmFuZW0pO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChWYW5lbS5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKFZhbmVtKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgbG9hZGVkRGF0YTogZmFsc2UsXG4gICAgICAgICAgICBkb2NJZDogcHJvcHMuZG9jSWQgPyBwcm9wcy5kb2NJZCA6IE51bWJlcihwcm9wcy5tYXRjaC5wYXJhbXMuZG9jSWQpLFxuICAgICAgICAgICAgbGFwc0lkOiBudWxsLFxuICAgICAgICAgICAgbW9kdWxlOiAnbGFwc2VkJ1xuICAgICAgICB9O1xuXG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmhhbmRsZVBhZ2VDbGljayA9IF90aGlzLmhhbmRsZVBhZ2VDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlTGFzdGVHcmlkQnRuQ2xpY2sgPSBfdGhpcy5oYW5kbGVMYXN0ZUdyaWRCdG5DbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuYnRuRWRpdEFzdXR1c0NsaWNrID0gX3RoaXMuYnRuRWRpdEFzdXR1c0NsaWNrLmJpbmQoX3RoaXMpO1xuXG4gICAgICAgIF90aGlzLnBhZ2VzID0gW3sgcGFnZU5hbWU6ICdWYW5lbSBrYWFydCcsIGRvY1R5cGVJZDogJ1ZBTkVNJyB9LCB7IHBhZ2VOYW1lOiAnQXJ2ZWQnLCBoYW5kbGVQYWdlQ2xpY2s6IF90aGlzLmhhbmRsZVBhZ2VDbGljaywgZG9jVHlwZUlkOiAnQVJWJyB9LCB7IHBhZ2VOYW1lOiAnTWFrc2Vrb3JhbGR1c2VkJywgaGFuZGxlUGFnZUNsaWNrOiBfdGhpcy5oYW5kbGVQYWdlQ2xpY2ssIGRvY1R5cGVJZDogJ1NNSycgfSwgeyBwYWdlTmFtZTogJ0thc3Nhb3JkZXJpZCcsIGhhbmRsZVBhZ2VDbGljazogX3RoaXMuaGFuZGxlUGFnZUNsaWNrLCBkb2NUeXBlSWQ6ICdTT1JERVInIH1dO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKFZhbmVtLCBbe1xuICAgICAgICBrZXk6ICdjb21wb25lbnREaWRNb3VudCcsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBjb21wb25lbnREaWRNb3VudCgpIHtcbiAgICAgICAgICAgIGlmICh0aGlzLnByb3BzLmhpc3RvcnkgJiYgdGhpcy5wcm9wcy5oaXN0b3J5LmxvY2F0aW9uLnN0YXRlKSB7XG4gICAgICAgICAgICAgICAgdmFyIGxhcHNJZCA9IHRoaXMucHJvcHMuaGlzdG9yeS5sb2NhdGlvbi5zdGF0ZS5sYXBzSWQ7XG4gICAgICAgICAgICAgICAgdmFyIF9tb2R1bGUgPSB0aGlzLnByb3BzLmhpc3RvcnkubG9jYXRpb24uc3RhdGUubW9kdWxlO1xuICAgICAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyBsYXBzSWQ6IGxhcHNJZCwgbW9kdWxlOiBfbW9kdWxlIH0pO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgdmFyIGluaXREYXRhID0gdGhpcy5wcm9wcy5pbml0RGF0YSA/IHRoaXMucHJvcHMuaW5pdERhdGEgOiB7fTtcblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRUZW1wbGF0ZSwgeyBkb2NJZDogdGhpcy5zdGF0ZS5kb2NJZCxcbiAgICAgICAgICAgICAgICByZWY6ICdkb2N1bWVudCcsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiAnVkFORU0nLFxuICAgICAgICAgICAgICAgIG1vZHVsZTogdGhpcy5zdGF0ZS5tb2R1bGUsXG4gICAgICAgICAgICAgICAgdXNlckRhdGE6IHRoaXMucHJvcHMudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgaW5pdERhdGE6IGluaXREYXRhLFxuICAgICAgICAgICAgICAgIGxpYnM6IExJQlJBUklFUyxcbiAgICAgICAgICAgICAgICBwYWdlczogdGhpcy5wYWdlcyxcbiAgICAgICAgICAgICAgICByZW5kZXJlcjogdGhpcy5yZW5kZXJlcixcbiAgICAgICAgICAgICAgICBoYW5kbGVHcmlkQnRuQ2xpY2s6IHRoaXMuaGFuZGxlTGFzdGVHcmlkQnRuQ2xpY2ssXG4gICAgICAgICAgICAgICAgZm9jdXNFbGVtZW50OiAnaW5wdXQtaXNpa3Vrb29kJ1xuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKtCS0LXRgNC90LXRgiDQutCw0YHRgtC+0LzQvdGL0LUg0LrQvtC80L/QvtC90LXQvdGC0Ysg0LTQvtC60YPQvNC10L3RgtCwXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcmVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcmVyKHNlbGYpIHtcbiAgICAgICAgICAgIHZhciBpc0VkaXRNb2RlID0gc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgZ3JpZExhc3RlRGF0YSA9IHNlbGYuZG9jRGF0YS5sYXBzZWQsXG4gICAgICAgICAgICAgICAgZ3JpZExhc3RlQ29sdW1ucyA9IHNlbGYuZG9jRGF0YS5ncmlkQ29uZmlnO1xuXG4gICAgICAgICAgICBpZiAodGhpcy5zdGF0ZS5sYXBzSWQpIHtcbiAgICAgICAgICAgICAgICBzZWxmLmRvY0RhdGEucGFyZW50aWQgPSB0aGlzLnN0YXRlLmxhcHNJZDtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvYyB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0RGF0YSwgeyB0aXRsZTogJ1ZhbmVtOicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2FzdXR1c2lkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBsaWJOYW1lOiAnYXN1dHVzZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNxbEZpZWxkczogWyduaW1ldHVzJywgJ3JlZ2tvb2QnXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBbXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFzdXR1c2lkIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVmYXVsdFZhbHVlOiBzZWxmLmRvY0RhdGEudmFuZW1fbmltaSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBib3VuZFRvR3JpZDogJ25pbWV0dXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJvdW5kVG9EYXRhOiAndmFuZW1fbmltaScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LWFzdXR1c2lkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBidG5EZWxldGU6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHVzZXJEYXRhOiBzZWxmLnVzZXJEYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEJ1dHRvbkVkaXQsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdidG5FZGl0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrOiB0aGlzLmJ0bkVkaXRBc3V0dXNDbGljayxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzaG93OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLmJ0bkVkaXQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ1N1Z3VsdXM6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnc3VodHVtaW5lJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnN1aHR1bWluZSB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1zdWh0dW1pbmUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnQXJ2ZWxkdXM6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYXJ2ZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IFt7IG5hbWU6ICdKYWgnIH0sIHsgbmFtZTogJ0VpJyB9XSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFydmVkIHx8ICdFaScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sbElkOiAnbmFtZScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVmYXVsdFZhbHVlOiBzZWxmLmRvY0RhdGEuYXJ2ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LWFydmVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBidG5EZWxldGU6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuZG9jRGF0YS5hcnZlZCA9PT0gJ0phaCcgPyBSZWFjdC5jcmVhdGVFbGVtZW50KENoZWNrQm94LCB7IHRpdGxlOiAnUHJpbnQgcGFiZXJpbCA/JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna2FzX3BhYmVyaWwnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBCb29sZWFuKHNlbGYuZG9jRGF0YS5rYXNfcGFiZXJpbCksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnY2hlY2tib3hfa2FzX3BhYmVyaWwnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZVxuICAgICAgICAgICAgICAgICAgICAgICAgfSkgOiBudWxsLFxuICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5kb2NEYXRhLmFydmVkID09PSAnSmFoJyA/IFJlYWN0LmNyZWF0ZUVsZW1lbnQoQ2hlY2tCb3gsIHsgdGl0bGU6ICdFLWFydmUgPycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2thc19lYXJ2ZScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IEJvb2xlYW4oc2VsZi5kb2NEYXRhLmthc19lYXJ2ZSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnY2hlY2tib3hfa2FzX2VhcnZlJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGVcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pIDogbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuZG9jRGF0YS5hcnZlZCA9PT0gJ0phaCcgPyBSZWFjdC5jcmVhdGVFbGVtZW50KENoZWNrQm94LCB7IHRpdGxlOiAnS2FzIGVtYWlsID8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrYXNfZW1haWwnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBCb29sZWFuKHNlbGYuZG9jRGF0YS5rYXNfZW1haWwpLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2NoZWNrYm94X2thc19lbWFpbCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KSA6IG51bGxcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChUZXh0QXJlYSwgeyB0aXRsZTogJ01cXHhFNHJrdXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd0ZXh0YXJlYS1tdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5tdXVkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2xhYmVsJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVmOiAnbGFiZWwnIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAnTGFwc2VkJ1xuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KERhdGFHcmlkLCB7IHNvdXJjZTogJ2xhcHNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBncmlkRGF0YTogZ3JpZExhc3RlRGF0YSxcbiAgICAgICAgICAgICAgICAgICAgICAgIGdyaWRDb2x1bW5zOiBncmlkTGFzdGVDb2x1bW5zLFxuICAgICAgICAgICAgICAgICAgICAgICAgc2hvd1Rvb2xCYXI6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgaGFuZGxlR3JpZEJ0bkNsaWNrOiBzZWxmLmhhbmRsZUdyaWRCdG5DbGljayxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMuZ3JpZC5oZWFkZXJUYWJsZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ2xhcHMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnbGFzcHNlZC1kYXRhLWdyaWQnIH0pXG4gICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnaGFuZGxlUGFnZUNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZVBhZ2VDbGljayhwYWdlRG9jVHlwZUlkKSB7XG4gICAgICAgICAgICB2YXIgbmltaSA9IHRoaXMucmVmc1snZG9jdW1lbnQnXS5kb2NEYXRhLnZhbmVtX25pbWk7XG5cbiAgICAgICAgICAgIHRoaXMucHJvcHMuaGlzdG9yeS5wdXNoKHtcbiAgICAgICAgICAgICAgICBwYXRobmFtZTogJy9sYXBzZWQvJyArIHBhZ2VEb2NUeXBlSWQsXG4gICAgICAgICAgICAgICAgc3RhdGU6IHsgYXN1dHVzOiBuaW1pLCB0eXBlOiAndGV4dCcgfVxuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZUxhc3RlR3JpZEJ0bkNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZUxhc3RlR3JpZEJ0bkNsaWNrKGJ0bk5hbWUsIGFjdGl2ZVJvdywgaWQsIGRvY1R5cGVJZCkge1xuXG4gICAgICAgICAgICBzd2l0Y2ggKGJ0bk5hbWUpIHtcbiAgICAgICAgICAgICAgICBjYXNlIFwiZWRpdFwiOlxuICAgICAgICAgICAgICAgICAgICB0aGlzLnByb3BzLmhpc3RvcnkucHVzaCh7XG4gICAgICAgICAgICAgICAgICAgICAgICBwYXRobmFtZTogJy9sYXBzZWQvJyArIGRvY1R5cGVJZCArICcvJyArIGlkLFxuICAgICAgICAgICAgICAgICAgICAgICAgc3RhdGU6IHsgdmFuZW1JZDogdGhpcy5zdGF0ZS5kb2NJZCwgbW9kdWxlOiB0aGlzLnN0YXRlLm1vZHVsZSB9XG4gICAgICAgICAgICAgICAgICAgIH0pO1xuXG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIGNhc2UgXCJhZGRcIjpcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goe1xuICAgICAgICAgICAgICAgICAgICAgICAgcGF0aG5hbWU6ICcvbGFwc2VkLycgKyBkb2NUeXBlSWQgKyAnLzAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgc3RhdGU6IHsgdmFuZW1JZDogdGhpcy5zdGF0ZS5kb2NJZCwgbW9kdWxlOiB0aGlzLnN0YXRlLm1vZHVsZSB9XG4gICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICBjYXNlIFwiZGVsZXRlXCI6XG4gICAgICAgICAgICAgICAgICAgIGNvbnNvbGUubG9nKCdidG5EZWxldGUgY2xpY2tlZCcpO1xuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICBkZWZhdWx0OlxuICAgICAgICAgICAgICAgICAgICBjb25zb2xlLmxvZygnVmlnYW5lIGNsaWNrJyk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICAvLyDQvtCx0YDQsNCx0L7RgtGH0LjQuiDRgdC+0LHRi9GC0LjRjyDQutC70LjRgdC60LAg0L3QsCDQutC90L7Qv9C60LUg0YDQtdC00LDQutGC0LjRgNC+0LLQsNC90LjRjyDQutC+0L3RgtGALdCw0LPQtdC90YLQsFxuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdidG5FZGl0QXN1dHVzQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gYnRuRWRpdEFzdXR1c0NsaWNrKCkge1xuICAgICAgICAgICAgdmFyIGRvY0FzdXR1c0lkID0gdGhpcy5yZWZzWydkb2N1bWVudCddLmRvY0RhdGEuYXN1dHVzaWQ7XG5cbiAgICAgICAgICAgIC8vINC+0YHRg9GJ0LXRgdGC0LLQuNGCINC/0LXRgNC10YXQvtC0INC90LAg0LrQsNGA0YLQvtGH0LrRgyDQutC+0L3RgtGALdCw0LPQtdC90YLQsFxuICAgICAgICAgICAgdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goJy9sYXBzZWQvYXN1dHVzZWQvJyArIGRvY0FzdXR1c0lkKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBWYW5lbTtcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cblZhbmVtLnByb3BUeXBlcyA9IHtcbiAgICBkb2NJZDogUHJvcFR5cGVzLm51bWJlcixcbiAgICBpbml0RGF0YTogUHJvcFR5cGVzLm9iamVjdCxcbiAgICB1c2VyRGF0YTogUHJvcFR5cGVzLm9iamVjdFxufTtcblxuVmFuZW0uZGVmYXVsdFByb3BzID0ge1xuICAgIHBhcmFtczogeyBkb2NJZDogMCB9LFxuICAgIGluaXREYXRhOiB7fSxcbiAgICB1c2VyRGF0YToge31cbn07XG5cbm1vZHVsZS5leHBvcnRzID0gVmFuZW07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL3ZhbmVtL2RvY3VtZW50L2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMjQ3XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgZG9jUm93OiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ3JvdydcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBibHVlJ1xyXG4gICAgICAgICovXG4gICAgfSxcbiAgICBkb2NDb2x1bW46IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJyxcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCB5ZWxsb3cnLFxyXG4gICAgICAgICovXG4gICAgICAgIHdpZHRoOiAnNTAlJ1xuICAgIH0sXG4gICAgZG9jOiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ2NvbHVtbidcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBicm93bidcclxuICAgICAgICAqL1xuICAgIH0sXG5cbiAgICBncmlkOiB7XG4gICAgICAgIG1haW5UYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuICAgICAgICBoZWFkZXJUYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuXG4gICAgICAgIGdyaWRDb250YWluZXI6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfVxuXG4gICAgfSxcblxuICAgIGdyaWRSb3c6IHtcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBibGFjaycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgYmFja2dyb3VuZENvbG9yOiAnd2hpdGUnLFxuICAgICAgICBwb3NpdGlvbjogJ3JlbGF0aXZlJyxcbiAgICAgICAgbWFyZ2luOiAnMTAlIDMwJSAxMCUgMzAlJyxcbiAgICAgICAgd2lkdGg6ICdhdXRvJyxcbiAgICAgICAgb3BhY2l0eTogJzEnLFxuICAgICAgICB0b3A6ICcxMDBweCdcbiAgICB9LFxuXG4gICAgYnRuRWRpdDoge1xuICAgICAgICB3aWR0aDogJ21pbi1jb250ZW50J1xuICAgIH1cblxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvdmFuZW0vZG9jdW1lbnQvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyNDhcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgRG9jdW1lbnRSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jdW1lbnRzL2RvY3VtZW50cy5qc3gnKTtcbnZhciBzdHlsZXMgPSByZXF1aXJlKCcuL3N0eWxlcycpO1xudmFyIERPQ19UWVBFX0lEID0gJ1ZBTkVNJztcbnZhciB0b29sYmFyUGFyYW1zID0ge1xuICAgIGJ0bkFkZDoge1xuICAgICAgICBzaG93OiBmYWxzZSxcbiAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgfSxcbiAgICBidG5FZGl0OiB7XG4gICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgIH0sXG4gICAgYnRuRGVsZXRlOiB7XG4gICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgIH0sXG4gICAgYnRuUHJpbnQ6IHtcbiAgICAgICAgc2hvdzogdHJ1ZSxcbiAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgfVxufTtcblxuLyoqXHJcbiAqINCa0LvQsNGB0YEg0YDQtdCw0LvQuNC30YPQtdGCINC00L7QutGD0LzQtdC90YIg0YHQv9GA0LDQstC+0YfQvdC40LrQsCDQv9GA0LjQt9C90LDQutC+0LIuXHJcbiAqL1xuXG52YXIgRG9jdW1lbnRzID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKERvY3VtZW50cywgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gRG9jdW1lbnRzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBEb2N1bWVudHMpO1xuXG4gICAgICAgIHJldHVybiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoRG9jdW1lbnRzLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoRG9jdW1lbnRzKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2N1bWVudHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50UmVnaXN0ZXIsIHsgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgdXNlckRhdGE6IHRoaXMucHJvcHMudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICBtb2R1bGU6IHRoaXMucHJvcHMubW9kdWxlLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6IERPQ19UWVBFX0lELFxuICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMsXG4gICAgICAgICAgICAgICAgdG9vbGJhclBhcmFtczogdG9vbGJhclBhcmFtcyxcbiAgICAgICAgICAgICAgICByZW5kZXI6IHRoaXMucmVuZGVyZXIgfSk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcmVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcmVyKCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICAnVmFuZW1hdGUgcmVnaXN0ZXIgc3BlY2lhbCByZW5kZXInXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIERvY3VtZW50cztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gRG9jdW1lbnRzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy92YW5lbS9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDI0OVxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9XG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy92YW5lbS9zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDI1MFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcbnZhciBEb2N1bWVudFJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2N1bWVudHMvZG9jdW1lbnRzLmpzeCcpO1xudmFyIHN0eWxlcyA9IHJlcXVpcmUoJy4vc3R5bGVzJyk7XG52YXIgRE9DX1RZUEVfSUQgPSAnTEFQU0VfR1JVUFAnO1xuXG4vKipcclxuICog0JrQu9Cw0YHRgSDRgNC10LDQu9C40LfRg9C10YIg0LTQvtC60YPQvNC10L3RgiDRgdC/0YDQsNCy0L7Rh9C90LjQutCwINC/0YDQuNC30L3QsNC60L7Qsi5cclxuICovXG5cbnZhciBEb2N1bWVudHMgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoRG9jdW1lbnRzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBEb2N1bWVudHMocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIERvY3VtZW50cyk7XG5cbiAgICAgICAgcmV0dXJuIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChEb2N1bWVudHMuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihEb2N1bWVudHMpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKERvY3VtZW50cywgW3tcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50UmVnaXN0ZXIsIHsgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgdXNlckRhdGE6IHRoaXMucHJvcHMudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICBtb2R1bGU6IHRoaXMucHJvcHMubW9kdWxlLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6IERPQ19UWVBFX0lELFxuICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMsXG4gICAgICAgICAgICAgICAgcmVuZGVyOiB0aGlzLnJlbmRlcmVyIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgJ0xhcHNlIGdydXBwIHJlZ2lzdGVyIHNwZWNpYWwgcmVuZGVyJ1xuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBEb2N1bWVudHM7XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5tb2R1bGUuZXhwb3J0cyA9IERvY3VtZW50cztcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvbGFwc2VfZ3J1cHAvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyODJcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBncmlkOiB7XG4gICAgICAgIG1haW5UYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuICAgICAgICBoZWFkZXJUYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuXG4gICAgICAgIGdyaWRDb250YWluZXI6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfVxuXG4gICAgfVxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvbGFwc2VfZ3J1cHAvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyODNcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBQcm9wVHlwZXMgPSByZXF1aXJlKCdwcm9wLXR5cGVzJyk7XG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xuXG52YXIgRG9jdW1lbnRUZW1wbGF0ZSA9IHJlcXVpcmUoJy4uLy4uL2RvY3VtZW50VGVtcGxhdGUvaW5kZXguanN4JyksXG4gICAgSW5wdXRUZXh0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC10ZXh0L2lucHV0LXRleHQuanN4JyksXG4gICAgU2VsZWN0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3Qvc2VsZWN0LmpzeCcpLFxuICAgIElucHV0TnVtYmVyID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC1udW1iZXIvaW5wdXQtbnVtYmVyLmpzeCcpLFxuICAgIFRleHRBcmVhID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy90ZXh0LWFyZWEvdGV4dC1hcmVhLmpzeCcpLFxuICAgIERhdGFHcmlkID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9kYXRhLWdyaWQvZGF0YS1ncmlkLmpzeCcpLFxuICAgIE1vZGFsUGFnZSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvbW9kYWxwYWdlL21vZGFsUGFnZS5qc3gnKSxcbiAgICBzdHlsZXMgPSByZXF1aXJlKCcuL3N0eWxlcycpO1xuXG52YXIgTElCUkFSSUVTID0gW3sgaWQ6ICdub21lbmNsYXR1cmUnLCBmaWx0ZXI6ICd3aGVyZSBkb2sgPSBcXCdBUlZcXCcnIH1dO1xuXG52YXIgTGFwc2VHcnVwcCA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhMYXBzZUdydXBwLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBMYXBzZUdydXBwKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBMYXBzZUdydXBwKTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoTGFwc2VHcnVwcC5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKExhcHNlR3J1cHApKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMuc3RhdGUgPSB7XG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCksXG4gICAgICAgICAgICBtb2R1bGU6ICdsYXBzZWQnXG4gICAgICAgIH07XG5cbiAgICAgICAgX3RoaXMucmVuZGVyZXIgPSBfdGhpcy5yZW5kZXJlci5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuY3JlYXRlR3JpZFJvdyA9IF90aGlzLmNyZWF0ZUdyaWRSb3cuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmdyaWRWYWxpZGF0ZUZpZWxkcyA9IF90aGlzLmdyaWRWYWxpZGF0ZUZpZWxkcy5iaW5kKF90aGlzKTtcblxuICAgICAgICAvLyAgICAgICAgdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2sgPSB0aGlzLmhhbmRsZUdyaWRCdG5DbGljay5iaW5kKHRoaXMpO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKExhcHNlR3J1cHAsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICB2YXIgaW5pdERhdGEgPSB0aGlzLnByb3BzLmluaXREYXRhID8gdGhpcy5wcm9wcy5pbml0RGF0YSA6IHt9O1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFRlbXBsYXRlLCB7IGRvY0lkOiB0aGlzLnN0YXRlLmRvY0lkLFxuICAgICAgICAgICAgICAgIHJlZjogJ2RvY3VtZW50JyxcbiAgICAgICAgICAgICAgICBtb2R1bGU6IHRoaXMuc3RhdGUubW9kdWxlLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ0xBUFNFX0dSVVBQJyxcbiAgICAgICAgICAgICAgICBsaWJzOiBMSUJSQVJJRVMsXG4gICAgICAgICAgICAgICAgdXNlckRhdGE6IHRoaXMucHJvcHMudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgaW5pdERhdGE6IGluaXREYXRhLFxuICAgICAgICAgICAgICAgIHJlbmRlcmVyOiB0aGlzLnJlbmRlcmVyLFxuICAgICAgICAgICAgICAgIGNyZWF0ZUdyaWRSb3c6IHRoaXMuY3JlYXRlR3JpZFJvdyxcbiAgICAgICAgICAgICAgICBncmlkVmFsaWRhdG9yOiB0aGlzLmdyaWRWYWxpZGF0ZUZpZWxkcyxcbiAgICAgICAgICAgICAgICBoaXN0b3J5OiB0aGlzLnByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgZm9jdXNFbGVtZW50OiAnaW5wdXQta29vZCdcbiAgICAgICAgICAgIH0pO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICrQktC10YDQvdC10YIg0LrQsNGB0YLQvtC80L3Ri9C1INC60L7QvNC/0L7QvdC10L3RgtGLINC00L7QutGD0LzQtdC90YLQsFxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcihzZWxmKSB7XG4gICAgICAgICAgICB2YXIgaXNFZGl0TW9kZSA9IHNlbGYuc3RhdGUuZWRpdGVkO1xuXG4gICAgICAgICAgICBpZiAoKHNlbGYuZG9jRGF0YS5pZCA9PT0gMCB8fCAhc2VsZi5kb2NEYXRhLnBhcmVudGlkKSAmJiB0aGlzLnN0YXRlLmxhcHNJZCkge1xuICAgICAgICAgICAgICAgIC8vbmV3IHJlY29yZFxuICAgICAgICAgICAgICAgIHNlbGYuZG9jRGF0YS5wYXJlbnRpZCA9IHRoaXMuc3RhdGUubGFwc0lkO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICB2YXIgZ3JpZFZhbHVlID0gdm9pZCAwO1xuICAgICAgICAgICAgaWYgKHNlbGYuZ3JpZFJvd0RhdGEpIHtcbiAgICAgICAgICAgICAgICBncmlkVmFsdWUgPSBzZWxmLmdyaWRSb3dEYXRhLmlkID8gc2VsZi5ncmlkUm93RGF0YS5pZCA6IG51bGw7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2MgfSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ0tvb2Q6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna29vZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5rb29kIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LWtvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnTmltZXR1czonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICduaW1ldHVzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLm5pbWV0dXMgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtbmltZXR1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnbGFiZWwnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ0FsbCBcXHhGQ2tzdXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYWxsX3lrc3VzXzEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFsbF95a3N1c18xIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1hbGxfeWtzdXNfMScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYWxsX3lrc3VzXzInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFsbF95a3N1c18yIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1hbGxfeWtzdXNfMicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYWxsX3lrc3VzXzMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFsbF95a3N1c18zIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1hbGxfeWtzdXNfMycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYWxsX3lrc3VzXzQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFsbF95a3N1c180IHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1hbGxfeWtzdXNfNCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYWxsX3lrc3VzXzUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFsbF95a3N1c181IHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1hbGxfeWtzdXNfNScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEYXRhR3JpZCwgeyBzb3VyY2U6ICd0ZWVudXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBncmlkRGF0YTogc2VsZi5kb2NEYXRhLmdyaWREYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZENvbHVtbnM6IHNlbGYuZG9jRGF0YS5ncmlkQ29uZmlnLFxuICAgICAgICAgICAgICAgICAgICAgICAgc2hvd1Rvb2xCYXI6IGlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICBjcmVhdGVHcmlkUm93OiB0aGlzLmNyZWF0ZUdyaWRSb3csXG4gICAgICAgICAgICAgICAgICAgICAgICBoYW5kbGVHcmlkUm93OiBzZWxmLmhhbmRsZUdyaWRSb3csXG4gICAgICAgICAgICAgICAgICAgICAgICBoYW5kbGVHcmlkQnRuQ2xpY2s6IHNlbGYuaGFuZGxlR3JpZEJ0bkNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGU6IHN0eWxlcy5ncmlkLmhlYWRlclRhYmxlLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnZGF0YS1ncmlkJyB9KVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChUZXh0QXJlYSwgeyB0aXRsZTogJ01cXHhFNHJrdXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd0ZXh0YXJlYS1tdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5tdXVkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBzZWxmLnN0YXRlLmdyaWRSb3dFZGl0ID8gdGhpcy5jcmVhdGVHcmlkUm93KHNlbGYpIDogbnVsbFxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINGE0L7RgNC80LjRgNGD0LXRgiDQvtCx0YrQtdC60YLRiyDQvNC+0LTQsNC70YzQvdC+0LPQviDQvtC60L3QsCDRgNC10LTQsNC60YLQuNGA0L7QstCw0L3QuNGPINGB0YLRgNC+0LrQuCDQs9GA0LjQtNCwXHJcbiAgICAgICAgICogQHJldHVybnMge1hNTH1cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnY3JlYXRlR3JpZFJvdycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBjcmVhdGVHcmlkUm93KHNlbGYpIHtcbiAgICAgICAgICAgIHZhciByb3cgPSBzZWxmLmdyaWRSb3dEYXRhID8gc2VsZi5ncmlkUm93RGF0YSA6IHt9LFxuICAgICAgICAgICAgICAgIHZhbGlkYXRlTWVzc2FnZSA9ICcnLFxuICAgICAgICAgICAgICAgIC8vIHNlbGYuc3RhdGUud2FybmluZ1xuICAgICAgICAgICAgYnV0dG9uT2tSZWFkT25seSA9IHZhbGlkYXRlTWVzc2FnZS5sZW5ndGggPiAwIHx8ICFzZWxmLnN0YXRlLmNoZWNrZWQsXG4gICAgICAgICAgICAgICAgbW9kYWxPYmplY3RzID0gWydidG5PaycsICdidG5DYW5jZWwnXTtcblxuICAgICAgICAgICAgaWYgKGJ1dHRvbk9rUmVhZE9ubHkpIHtcbiAgICAgICAgICAgICAgICAvLyDRg9Cx0LXRgNC10Lwg0LrQvdC+0L/QutGDINCe0LpcbiAgICAgICAgICAgICAgICBtb2RhbE9iamVjdHMuc3BsaWNlKDAsIDEpO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAoIXJvdykgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoJ2RpdicsIG51bGwpO1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IGNsYXNzTmFtZTogJy5tb2RhbFBhZ2UnIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgTW9kYWxQYWdlLFxuICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICBtb2RhbE9iamVjdHM6IG1vZGFsT2JqZWN0cyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ21vZGFscGFnZS1ncmlkLXJvdycsXG4gICAgICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgbW9kYWxQYWdlQnRuQ2xpY2s6IHNlbGYubW9kYWxQYWdlQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICBtb2RhbFBhZ2VOYW1lOiAnUmVhIGxpc2FtaW5lIC8gcGFyYW5kYW1pbmUnIH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVmOiAnZ3JpZC1yb3ctY29udGFpbmVyJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5zdGF0ZS5ncmlkV2FybmluZy5sZW5ndGggPyBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnc3BhbicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuc3RhdGUuZ3JpZFdhcm5pbmdcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgICAgICApIDogbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnVGVlbnVzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ25vbWlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbGliczogJ25vbWVuY2xhdHVyZScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHNlbGYubGlic1snbm9tZW5jbGF0dXJlJ10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIocm93Lm5vbWlkKSB8fCAwLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHJvdy5rb29kIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdub21pZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGxJZDogJ2lkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGxhY2Vob2xkZXI6ICdUZWVudXNlIGtvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVHcmlkUm93Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dE51bWJlciwgeyB0aXRsZTogJ0tvZ3VzOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna29ndXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHJvdy5rb2d1cykgfHwgMSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYmluZERhdGE6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdrb2d1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUdyaWRSb3dJbnB1dCB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgdGl0bGU6ICdIaW5kOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnaGluZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIocm93LmhpbmQpIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJpbmREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaGluZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUdyaWRSb3dJbnB1dCB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnc3BhbicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWxpZGF0ZU1lc3NhZ2VcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQstCw0LvQuNC00LDRgtC+0YAg0LTQu9GPINGB0YLRgNC+0LrQuCDQs9GA0LjQtNCwXHJcbiAgICAgICAgICogQHJldHVybnMge3N0cmluZ31cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnZ3JpZFZhbGlkYXRlRmllbGRzJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGdyaWRWYWxpZGF0ZUZpZWxkcygpIHtcbiAgICAgICAgICAgIHZhciB3YXJuaW5nID0gJyc7XG4gICAgICAgICAgICB2YXIgZG9jID0gdGhpcy5yZWZzWydkb2N1bWVudCddO1xuICAgICAgICAgICAgaWYgKGRvYyAmJiBkb2MuZ3JpZFJvd0RhdGEpIHtcblxuICAgICAgICAgICAgICAgIC8vINGC0L7Qu9GM0LrQviDQv9C+0YHQu9C1INC/0YDQvtCy0LXRgNC60Lgg0YTQvtGA0LzRiyDQvdCwINCy0LDQu9C40LTQvdC+0YHRgtGMXG4gICAgICAgICAgICAgICAgaWYgKGRvYy5ncmlkUm93RGF0YSAmJiAhZG9jLmdyaWRSb3dEYXRhWydub21pZCddKSB3YXJuaW5nID0gd2FybmluZyArICcgUHV1ZHViIG9wZXJhdHNpb29uJztcblxuICAgICAgICAgICAgICAgIC8v0L/QvtC00YHRgtCw0LLQuNC8INC90LDQuNC80LXQvdC+0LLQsNC90LjQtSDRg9GB0LvQvtCz0YNcblxuICAgICAgICAgICAgICAgIGlmIChkb2MuZ3JpZFJvd0RhdGFbJ25vbWlkJ10pIHtcblxuICAgICAgICAgICAgICAgICAgICB2YXIgbm9tRGF0YU5hbWUgPSBkb2MubGlic1snbm9tZW5jbGF0dXJlJ10uZmluZChmdW5jdGlvbiAobGliKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gTnVtYmVyKGxpYi5pZCkgPT09IE51bWJlcihkb2MuZ3JpZFJvd0RhdGFbJ25vbWlkJ10pO1xuICAgICAgICAgICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgICAgICAgICBkb2MuZ3JpZFJvd0RhdGFbJ2tvb2QnXSA9IG5vbURhdGFOYW1lLmtvb2Q7XG4gICAgICAgICAgICAgICAgICAgIGRvYy5ncmlkUm93RGF0YVsnbmltZXR1cyddID0gbm9tRGF0YU5hbWUubmltZXR1cztcblxuICAgICAgICAgICAgICAgICAgICBpZiAoIWRvYy5ncmlkUm93RGF0YVsnaGluZCddKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBkb2MuZ3JpZFJvd0RhdGFbJ2hpbmQnXSA9IG5vbURhdGFOYW1lLmhpbmQ7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgICAgICBpZiAoIWRvYy5ncmlkUm93RGF0YVsna29ndXMnXSkge1xuICAgICAgICAgICAgICAgICAgICBkb2MuZ3JpZFJvd0RhdGFbJ2tvZ3VzJ10gPSAxO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybiB3YXJuaW5nO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIExhcHNlR3J1cHA7XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5MYXBzZUdydXBwLnByb3BUeXBlcyA9IHtcbiAgICBkb2NJZDogUHJvcFR5cGVzLm51bWJlcixcbiAgICBpbml0RGF0YTogUHJvcFR5cGVzLm9iamVjdCxcbiAgICB1c2VyRGF0YTogUHJvcFR5cGVzLm9iamVjdFxufTtcblxuTGFwc2VHcnVwcC5kZWZhdWx0UHJvcHMgPSB7XG4gICAgcGFyYW1zOiB7IGRvY0lkOiAwIH0sXG4gICAgaW5pdERhdGE6IHt9LFxuICAgIHVzZXJEYXRhOiB7fVxufTtcblxubW9kdWxlLmV4cG9ydHMgPSBMYXBzZUdydXBwO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9sYXBzZV9ncnVwcC9kb2N1bWVudC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDI4NFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGRvY1Jvdzoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdyb3cnXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYmx1ZSdcclxuICAgICAgICAqL1xuICAgIH0sXG4gICAgZG9jQ29sdW1uOiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ2NvbHVtbicsXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgeWVsbG93JyxcclxuICAgICAgICAqL1xuICAgICAgICB3aWR0aDogJzUwJSdcbiAgICB9LFxuICAgIGRvYzoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYnJvd24nXHJcbiAgICAgICAgKi9cbiAgICB9LFxuXG4gICAgZ3JpZDoge1xuICAgICAgICBtYWluVGFibGU6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfSxcbiAgICAgICAgaGVhZGVyVGFibGU6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfSxcblxuICAgICAgICBncmlkQ29udGFpbmVyOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH1cblxuICAgIH0sXG5cbiAgICBncmlkUm93OiB7XG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYmxhY2snLFxyXG4gICAgICAgICovXG4gICAgICAgIGJhY2tncm91bmRDb2xvcjogJ3doaXRlJyxcbiAgICAgICAgcG9zaXRpb246ICdyZWxhdGl2ZScsXG4gICAgICAgIG1hcmdpbjogJzEwJSAzMCUgMTAlIDMwJScsXG4gICAgICAgIHdpZHRoOiAnYXV0bycsXG4gICAgICAgIG9wYWNpdHk6ICcxJyxcbiAgICAgICAgdG9wOiAnMTAwcHgnXG4gICAgfSxcblxuICAgIGJ0bkVkaXROb206IHtcbiAgICAgICAgd2lkdGg6ICdtaW4tY29udGVudCdcbiAgICB9LFxuXG4gICAgc2VsZWN0Tm9tOiB7XG4gICAgICAgIG1hcmdpbkxlZnQ6ICcxMHB4J1xuICAgIH1cblxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvbGFwc2VfZ3J1cHAvZG9jdW1lbnQvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyODVcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgRG9jdW1lbnRSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jdW1lbnRzL2RvY3VtZW50cy5qc3gnKTtcblxudmFyIHN0eWxlcyA9IHJlcXVpcmUoJy4vc3R5bGVzJyk7XG52YXIgRE9DX1RZUEVfSUQgPSAnUEFOS19WVic7XG52YXIgdG9vbGJhclBhcmFtcyA9IHtcbiAgICBidG5BZGQ6IHtcbiAgICAgICAgc2hvdzogZmFsc2VcbiAgICB9LFxuICAgIGJ0bkVkaXQ6IHtcbiAgICAgICAgc2hvdzogdHJ1ZVxuICAgIH0sXG4gICAgYnRuRGVsZXRlOiB7XG4gICAgICAgIHNob3c6IHRydWVcbiAgICB9LFxuICAgIGJ0blByaW50OiB7XG4gICAgICAgIHNob3c6IGZhbHNlXG4gICAgfSxcbiAgICBidG5TdGFydDoge1xuICAgICAgICBzaG93OiBmYWxzZVxuICAgIH1cbn07XG5cbi8qKlxyXG4gKiDQmtC70LDRgdGBINGA0LXQsNC70LjQt9GD0LXRgiDQtNC+0LrRg9C80LXQvdGCINGB0L/RgNCw0LLQvtGH0L3QuNC60LAg0L/RgNC40LfQvdCw0LrQvtCyLlxyXG4gKi9cblxudmFyIERvY3VtZW50cyA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhEb2N1bWVudHMsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIERvY3VtZW50cyhwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgRG9jdW1lbnRzKTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoRG9jdW1lbnRzLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoRG9jdW1lbnRzKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLmJ0bkVkaXRDbGljayA9IF90aGlzLmJ0bkVkaXRDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuRG9jID0gbnVsbDsgLy/RgdGB0YvQu9C60LAg0L3QsCDRgdGC0YDQsNC90LjRhtGDXG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLnJlbmRlciA9IF90aGlzLnJlbmRlci5iaW5kKF90aGlzKTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2N1bWVudHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICB2YXIgc3RhdGUgPSB0aGlzLkRvYyAmJiB0aGlzLkRvYy5zdGF0ZSA/IHRoaXMuRG9jLnN0YXRlIDogbnVsbDtcbiAgICAgICAgICAgIGlmICh0aGlzLkRvYykge1xuICAgICAgICAgICAgICAgIHRvb2xiYXJQYXJhbXNbJ2J0bkVkaXQnXS5zaG93ID0gc3RhdGUudmFsdWUgPyB0cnVlIDogZmFsc2U7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50UmVnaXN0ZXIsIHsgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICBtb2R1bGU6IHRoaXMucHJvcHMubW9kdWxlLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6IERPQ19UWVBFX0lELFxuICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMsXG4gICAgICAgICAgICAgICAgdG9vbGJhclBhcmFtczogdG9vbGJhclBhcmFtcyxcbiAgICAgICAgICAgICAgICBidG5FZGl0Q2xpY2s6IHRoaXMuYnRuRWRpdENsaWNrLFxuICAgICAgICAgICAgICAgIHJlbmRlcjogdGhpcy5yZW5kZXJlciB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgdGhpcy5Eb2MgPSBzZWxmO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdidG5FZGl0Q2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gYnRuRWRpdENsaWNrKCkge1xuICAgICAgICAgICAgLy8g0LrQsNGB0YLQvtC80L3Ri9C5INC+0LHRgNCw0LHQvtGC0YfQuNC6INGB0L7QsdGL0YLQuNGPXG4gICAgICAgICAgICBpZiAodGhpcy5Eb2MgJiYgdGhpcy5Eb2Muc3RhdGUpIHtcbiAgICAgICAgICAgICAgICB2YXIgdmFsdWUgPSB0aGlzLkRvYy5zdGF0ZS52YWx1ZTtcbiAgICAgICAgICAgICAgICB2YXIgZ3JpZERhdGEgPSB0aGlzLkRvYy5ncmlkRGF0YTtcbiAgICAgICAgICAgICAgICB2YXIgZG9jX2lkID0gZ3JpZERhdGEuZmluZChmdW5jdGlvbiAocm93KSB7XG4gICAgICAgICAgICAgICAgICAgIHJldHVybiByb3cuaWQgPSB2YWx1ZTtcbiAgICAgICAgICAgICAgICB9KS5kb2NfaWQ7XG4gICAgICAgICAgICAgICAgaWYgKGRvY19pZCkge1xuICAgICAgICAgICAgICAgICAgICByZXR1cm4gdGhpcy5wcm9wcy5oaXN0b3J5LnB1c2goe1xuICAgICAgICAgICAgICAgICAgICAgICAgcGF0aG5hbWU6ICcvJyArIHRoaXMucHJvcHMubW9kdWxlICsgJy9TTUsvJyArIGRvY19pZCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHN0YXRlOiB7IG1vZHVsZTogdGhpcy5wcm9wcy5tb2R1bGUgfVxuICAgICAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICB0aGlzLkRvYy5zZXRTdGF0ZSh7XG4gICAgICAgICAgICAgICAgICAgICAgICB3YXJuaW5nOiAnTWFrc2Vrb3JyYWxkdXMgZWkgbGVpZG51ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICB3YXJuaW5nVHlwZTogJ2Vycm9yJ1xuICAgICAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gRG9jdW1lbnRzO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxubW9kdWxlLmV4cG9ydHMgPSBEb2N1bWVudHM7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL3BhbmtfdnYvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyODZcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBncmlkOiB7XG4gICAgICAgIG1haW5UYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuICAgICAgICBoZWFkZXJUYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuXG4gICAgICAgIGdyaWRDb250YWluZXI6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfVxuXG4gICAgfVxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvcGFua192di9zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDI4N1xuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcbnZhciBQcm9wVHlwZXMgPSByZXF1aXJlKCdwcm9wLXR5cGVzJyk7XG5cbnZhciBEb2N1bWVudFRlbXBsYXRlID0gcmVxdWlyZSgnLi8uLi8uLi9kb2N1bWVudFRlbXBsYXRlL2luZGV4LmpzeCcpLFxuICAgIElucHV0VGV4dCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtdGV4dC9pbnB1dC10ZXh0LmpzeCcpLFxuICAgIFRleHRBcmVhID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy90ZXh0LWFyZWEvdGV4dC1hcmVhLmpzeCcpLFxuICAgIHN0eWxlcyA9IHJlcXVpcmUoJy4vc3R5bGVzJyk7XG5cbi8qKlxyXG4gKiDQmtC70LDRgdGBINGA0LXQsNC70LjQt9GD0LXRgiDQtNC+0LrRg9C80LXQvdGCINGB0L/RgNCw0LLQvtGH0L3QuNC60LAg0L/RgNC40LfQvdCw0LrQvtCyLlxyXG4gKi9cblxudmFyIENvbmZpZyA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhDb25maWcsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIENvbmZpZyhwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgQ29uZmlnKTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoQ29uZmlnLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoQ29uZmlnKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgZG9jSWQ6IHByb3BzLmRvY0lkID8gcHJvcHMuZG9jSWQgOiBOdW1iZXIocHJvcHMubWF0Y2gucGFyYW1zLmRvY0lkKSxcbiAgICAgICAgICAgIGxvYWRlZERhdGE6IGZhbHNlXG4gICAgICAgIH07XG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoQ29uZmlnLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRUZW1wbGF0ZSwgeyBkb2NJZDogdGhpcy5zdGF0ZS5kb2NJZCxcbiAgICAgICAgICAgICAgICByZWY6ICdkb2N1bWVudCcsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiAnQ09ORklHJyxcbiAgICAgICAgICAgICAgICBoaXN0b3J5OiB0aGlzLnByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnByb3BzLm1vZHVsZSxcbiAgICAgICAgICAgICAgICBpbml0RGF0YTogdGhpcy5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICByZW5kZXJlcjogdGhpcy5yZW5kZXJlclxuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQnNC10YLQvtC0INCy0LXRgNC90LXRgiDQutCw0YHRgtC+0LzQvdGL0Lkg0LrQvtC80L/QvtC90LXQvdGCXHJcbiAgICAgICAgICogQHBhcmFtIHNlbGZcclxuICAgICAgICAgKiBAcmV0dXJucyB7Kn1cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgaWYgKCFzZWxmLmRvY0RhdGEpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2MgfSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jQ29sdW1uIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ1ByZWZpa3M6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ251bWJlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtbnVtYmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIXNlbGYuc3RhdGUuZWRpdGVkLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubnVtYmVyIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdBcnZldGUgdGFodHBcXHhFNGV2ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3RhaHRwYWV2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC10YWh0cGFldicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnRhaHRwYWV2IHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdPbW5pdmEgZS1hcnZldGUgc2VydmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdlYXJ2ZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtZWFydmVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5lYXJ2ZWQgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIXNlbGYuc3RhdGUuZWRpdGVkIH0pXG4gICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBDb25maWc7XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5Db25maWcucHJvcFR5cGVzID0ge1xuICAgIGRvY0lkOiBQcm9wVHlwZXMubnVtYmVyLFxuICAgIGluaXREYXRhOiBQcm9wVHlwZXMub2JqZWN0XG59O1xuXG5Db25maWcuZGVmYXVsdFByb3BzID0ge1xuICAgIGluaXREYXRhOiB7fVxufTtcblxubW9kdWxlLmV4cG9ydHMgPSBDb25maWc7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2NvbmZpZy9kb2N1bWVudC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDI4OFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGRvY1Jvdzoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdyb3cnXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYmx1ZSdcclxuICAgICAgICAqL1xuICAgIH0sXG4gICAgZG9jQ29sdW1uOiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ2NvbHVtbicsXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgeWVsbG93JyxcclxuICAgICAgICAqL1xuICAgICAgICB3aWR0aDogJzUwJSdcbiAgICB9LFxuICAgIGRvYzoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYnJvd24nXHJcbiAgICAgICAgKi9cbiAgICB9XG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9jb25maWcvZG9jdW1lbnQvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyODlcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xuXG52YXIgRG9jdW1lbnRUZW1wbGF0ZSA9IHJlcXVpcmUoJy4vLi4vLi4vZG9jdW1lbnRUZW1wbGF0ZS9pbmRleC5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBEYXRhR3JpZCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvZGF0YS1ncmlkL2RhdGEtZ3JpZC5qc3gnKSxcbiAgICBUZXh0QXJlYSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvdGV4dC1hcmVhL3RleHQtYXJlYS5qc3gnKSxcbiAgICBNb2RhbFBhZ2UgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL21vZGFscGFnZS9tb2RhbFBhZ2UuanN4JyksXG4gICAgU2VsZWN0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3Qvc2VsZWN0LmpzeCcpLFxuICAgIENoZWNrQm94ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC1jaGVja2JveC9pbnB1dC1jaGVja2JveC5qc3gnKSxcbiAgICBzdHlsZXMgPSByZXF1aXJlKCcuL3N0eWxlcycpO1xuXG52YXIgTElCX09CSlMgPSBbeyBpZDogJ2tvbnRvZCcsIGZpbHRlcjogJycgfV07XG5cbi8qKlxyXG4gKiDQmtC70LDRgdGBINGA0LXQsNC70LjQt9GD0LXRgiDQtNC+0LrRg9C80LXQvdGCINGB0L/RgNCw0LLQvtGH0L3QuNC60LAg0L/RgNC40LfQvdCw0LrQvtCyLlxyXG4gKi9cblxudmFyIFJla3YgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoUmVrdiwgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gUmVrdihwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgUmVrdik7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKFJla3YuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihSZWt2KSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgZG9jSWQ6IHByb3BzLmRvY0lkID8gcHJvcHMuZG9jSWQgOiBOdW1iZXIocHJvcHMubWF0Y2gucGFyYW1zLmRvY0lkKSxcbiAgICAgICAgICAgIGxvYWRlZERhdGE6IGZhbHNlXG4gICAgICAgIH07XG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmNyZWF0ZUdyaWRSb3cgPSBfdGhpcy5jcmVhdGVHcmlkUm93LmJpbmQoX3RoaXMpO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKFJla3YsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFRlbXBsYXRlLCB7IGRvY0lkOiB0aGlzLnN0YXRlLmRvY0lkLFxuICAgICAgICAgICAgICAgIHJlZjogJ2RvY3VtZW50JyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6ICdSRUtWJyxcbiAgICAgICAgICAgICAgICBoaXN0b3J5OiB0aGlzLnByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnByb3BzLm1vZHVsZSxcbiAgICAgICAgICAgICAgICBsaWJzOiBMSUJfT0JKUyxcbiAgICAgICAgICAgICAgICBpbml0RGF0YTogdGhpcy5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICByZW5kZXJlcjogdGhpcy5yZW5kZXJlcixcbiAgICAgICAgICAgICAgICBjcmVhdGVHcmlkUm93OiB0aGlzLmNyZWF0ZUdyaWRSb3dcblxuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQnNC10YLQvtC0INCy0LXRgNC90LXRgiDQutCw0YHRgtC+0LzQvdGL0Lkg0LrQvtC80L/QvtC90LXQvdGCXHJcbiAgICAgICAgICogQHBhcmFtIHNlbGZcclxuICAgICAgICAgKiBAcmV0dXJucyB7Kn1cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgaWYgKCFzZWxmLmRvY0RhdGEpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHZhciBncmlkRGF0YSA9IHNlbGYuZG9jRGF0YS5ncmlkRGF0YSxcbiAgICAgICAgICAgICAgICBncmlkQ29sdW1ucyA9IHNlbGYuZG9jRGF0YS5ncmlkQ29uZmlnO1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdSZWdrb29kOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3JlZ2tvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtcmVna29vZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIXNlbGYuc3RhdGUuZWRpdGVkLFxuICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5yZWdrb29kIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSlcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnS0JNIGtvb2Q6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna2Jta29vZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1rYm1rb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmtibWtvb2QgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHRpdGxlOiAnTmltZXR1czogJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICduaW1ldHVzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LW5pbWV0dXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubmltZXR1cyB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ1RcXHhFNGlzLiBuaW1ldHVzOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ211dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIXNlbGYuc3RhdGUuZWRpdGVkLFxuICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5tdXVkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSlcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdBYWRyZXNzOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2FhZHJlc3MnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtYWFkcmVzcycsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuYWFkcmVzcyB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQgfSlcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnSnVoYXRhamE6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnanVodCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1qdWh0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmp1aHQgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdSYWFtYXR1cGlkYWphOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3JhYW1hJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXJhYW1hJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnJhYW1hIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSlcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnRW1haWw6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnZW1haWwnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtZW1haWwnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuZW1haWwgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdPbW5pdmEgc2FsYXNcXHhGNW5hOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2VhcnZlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1lYXJ2ZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuZWFydmVkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSlcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRGF0YUdyaWQsIHsgc291cmNlOiAnZGV0YWlscycsXG4gICAgICAgICAgICAgICAgICAgICAgICBncmlkRGF0YTogZ3JpZERhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICBncmlkQ29sdW1uczogZ3JpZENvbHVtbnMsXG4gICAgICAgICAgICAgICAgICAgICAgICBzaG93VG9vbEJhcjogc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICBoYW5kbGVHcmlkUm93OiB0aGlzLmhhbmRsZUdyaWRSb3csXG4gICAgICAgICAgICAgICAgICAgICAgICBoYW5kbGVHcmlkQnRuQ2xpY2s6IHNlbGYuaGFuZGxlR3JpZEJ0bkNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMuZ3JpZC5oZWFkZXJUYWJsZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2RhdGEtZ3JpZCcgfSlcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIHNlbGYuc3RhdGUuZ3JpZFJvd0VkaXQgPyB0aGlzLmNyZWF0ZUdyaWRSb3coc2VsZikgOiBudWxsXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0KHQvtC30LTQsNGB0YIg0LrQvtC80L/QvtC90LXRgiDRgdGC0YDQvtC60Lgg0LPRgNC40LTQsFxyXG4gICAgICAgICAqIEByZXR1cm5zIHtYTUx9XHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2NyZWF0ZUdyaWRSb3cnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gY3JlYXRlR3JpZFJvdyhzZWxmKSB7XG5cbiAgICAgICAgICAgIHZhciByb3cgPSBzZWxmLmdyaWRSb3dEYXRhID8gc2VsZi5ncmlkUm93RGF0YSA6IHt9LFxuICAgICAgICAgICAgICAgIHZhbGlkYXRlTWVzc2FnZSA9ICcnLFxuICAgICAgICAgICAgICAgIC8vIHNlbGYuc3RhdGUud2FybmluZ1xuICAgICAgICAgICAgYnV0dG9uT2tSZWFkT25seSA9IHZhbGlkYXRlTWVzc2FnZS5sZW5ndGggPiAwIHx8ICFzZWxmLnN0YXRlLmNoZWNrZWQsXG4gICAgICAgICAgICAgICAgbW9kYWxPYmplY3RzID0gWydidG5PaycsICdidG5DYW5jZWwnXTtcblxuICAgICAgICAgICAgaWYgKGJ1dHRvbk9rUmVhZE9ubHkpIHtcbiAgICAgICAgICAgICAgICAvLyDRg9Cx0LXRgNC10Lwg0LrQvdC+0L/QutGDINCe0LpcbiAgICAgICAgICAgICAgICBtb2RhbE9iamVjdHMuc3BsaWNlKDAsIDEpO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAoIXJvdykgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoJ2RpdicsIG51bGwpO1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IGNsYXNzTmFtZTogJy5tb2RhbFBhZ2UnIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgTW9kYWxQYWdlLFxuICAgICAgICAgICAgICAgICAgICB7XG4gICAgICAgICAgICAgICAgICAgICAgICBtb2RhbE9iamVjdHM6IG1vZGFsT2JqZWN0cyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ21vZGFscGFnZS1ncmlkLXJvdycsXG4gICAgICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgbW9kYWxQYWdlQnRuQ2xpY2s6IHNlbGYubW9kYWxQYWdlQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICBtb2RhbFBhZ2VOYW1lOiAnUmVhIGxpc2FtaW5lIC8gcGFyYW5kYW1pbmUnIH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgcmVmOiAnZ3JpZC1yb3ctY29udGFpbmVyJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5zdGF0ZS5ncmlkV2FybmluZy5sZW5ndGggPyBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnc3BhbicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuc3RhdGUuZ3JpZFdhcm5pbmdcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgICAgICApIDogbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnTnVtYmVyOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYXJ2ZScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiByb3cuYXJ2ZSB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJpbmREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnbnVtYmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlR3JpZFJvd0lucHV0IH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdOaW1ldHVzOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbmltZXR1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiByb3cubmltZXR1cyB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJpbmREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnbnVtYmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlR3JpZFJvd0lucHV0IH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChTZWxlY3QsIHsgdGl0bGU6ICdUXFx4RkNcXHhGQ3A6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrYXNzYXBhbmsnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBbeyBpZDogMCwgbmltZXR1czogJ0thc3NhJyB9LCB7IGlkOiAxLCBuaW1ldHVzOiAnUGFuaycgfSwgeyBpZDogMiwgbmltZXR1czogJ1RQJyB9XSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHJvdy5rYXNzYXBhbmsgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2thc3NhcGFuaycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGxJZDogJ2lkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlR3JpZFJvd0NoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnS29udG86ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrb250bycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHNlbGYubGlic1sna29udG9kJ10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiByb3cua29udG8gfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2tvbnRvJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sbElkOiAna29vZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUdyaWRSb3dDaGFuZ2UgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KENoZWNrQm94LCB7IHRpdGxlOiAnS2FzIHBcXHhGNWhpbGluZT8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnZGVmYXVsdF8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogQm9vbGVhbihzZWxmLmRvY0RhdGEuZGVmYXVsdF8pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdjaGVja2JveF9kZWZhdWx0XycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogZmFsc2VcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnc3BhbicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWxpZGF0ZU1lc3NhZ2VcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gUmVrdjtcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cblJla3YucHJvcFR5cGVzID0ge1xuICAgIGRvY0lkOiBQcm9wVHlwZXMubnVtYmVyLFxuICAgIGluaXREYXRhOiBQcm9wVHlwZXMub2JqZWN0XG59O1xuXG5SZWt2LmRlZmF1bHRQcm9wcyA9IHtcbiAgICBpbml0RGF0YToge31cbn07XG5cbm1vZHVsZS5leHBvcnRzID0gUmVrdjtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvcmVrdi9kb2N1bWVudC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDI5MFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGRvY1Jvdzoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdyb3cnXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYmx1ZSdcclxuICAgICAgICAqL1xuICAgIH0sXG4gICAgZG9jQ29sdW1uOiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ2NvbHVtbicsXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgeWVsbG93JyxcclxuICAgICAgICAqL1xuICAgICAgICB3aWR0aDogJzUwJSdcbiAgICB9LFxuICAgIGRvYzoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYnJvd24nXHJcbiAgICAgICAgKi9cbiAgICB9LFxuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9LFxuXG4gICAgZ3JpZFJvdzoge1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsYWNrJyxcclxuICAgICAgICAqL1xuICAgICAgICBiYWNrZ3JvdW5kQ29sb3I6ICd3aGl0ZScsXG4gICAgICAgIHBvc2l0aW9uOiAncmVsYXRpdmUnLFxuICAgICAgICBtYXJnaW46ICcxMCUgMzAlIDEwJSAzMCUnLFxuICAgICAgICB3aWR0aDogJ2F1dG8nLFxuICAgICAgICBvcGFjaXR5OiAnMScsXG4gICAgICAgIHRvcDogJzEwMHB4J1xuICAgIH0sXG5cbiAgICBidG5FZGl0OiB7XG4gICAgICAgIHdpZHRoOiAnbWluLWNvbnRlbnQnXG4gICAgfVxuXG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9yZWt2L2RvY3VtZW50L3N0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjkxXG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIFByb3BUeXBlcyA9IHJlcXVpcmUoJ3Byb3AtdHlwZXMnKTtcblxudmFyIERvY3VtZW50VGVtcGxhdGUgPSByZXF1aXJlKCcuLy4uLy4uL2RvY3VtZW50VGVtcGxhdGUvaW5kZXguanN4JyksXG4gICAgSW5wdXRUZXh0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9pbnB1dC10ZXh0L2lucHV0LXRleHQuanN4JyksXG4gICAgVGV4dEFyZWEgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL3RleHQtYXJlYS90ZXh0LWFyZWEuanN4JyksXG4gICAgU2VsZWN0ID0gcmVxdWlyZSgnLi4vLi4vLi4vY29tcG9uZW50cy9zZWxlY3Qvc2VsZWN0LmpzeCcpLFxuICAgIHN0eWxlcyA9IHJlcXVpcmUoJy4vc3R5bGVzJyk7XG52YXIgTElCUkFSSUVTID0gW3sgaWQ6ICdrb250b2QnLCBmaWx0ZXI6ICd3aGVyZSBsZW4oa29vZDo6dGV4dCkgPj0gNicgfV07XG5cbnZhciBQcm9qZWN0ID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKFByb2plY3QsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIFByb2plY3QocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIFByb2plY3QpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChQcm9qZWN0Ll9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoUHJvamVjdCkpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCksXG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZSxcbiAgICAgICAgICAgIGRvY1R5cGVJZDogX3RoaXMucHJvcHMuaGlzdG9yeS5sb2NhdGlvbi5zdGF0ZSA/IF90aGlzLnByb3BzLmhpc3RvcnkubG9jYXRpb24uc3RhdGUuZG9jUHJvcElkIDogJydcbiAgICAgICAgfTtcbiAgICAgICAgX3RoaXMucmVuZGVyZXIgPSBfdGhpcy5yZW5kZXJlci5iaW5kKF90aGlzKTtcblxuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKFByb2plY3QsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFRlbXBsYXRlLCB7IGRvY0lkOiB0aGlzLnN0YXRlLmRvY0lkLFxuICAgICAgICAgICAgICAgIHJlZjogJ2RvY3VtZW50JyxcbiAgICAgICAgICAgICAgICBoaXN0b3J5OiB0aGlzLnByb3BzLmhpc3RvcnksXG4gICAgICAgICAgICAgICAgbGliczogTElCUkFSSUVTLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ0RPS1BST1BTJyxcbiAgICAgICAgICAgICAgICBpbml0RGF0YTogdGhpcy5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICByZW5kZXJlcjogdGhpcy5yZW5kZXJlciB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINCc0LXRgtC+0LQg0LLQtdGA0L3QtdGCINC60LDRgdGC0L7QvNC90YvQuSDQutC+0LzQv9C+0L3QtdC90YJcclxuICAgICAgICAgKiBAcGFyYW0gc2VsZlxyXG4gICAgICAgICAqIEByZXR1cm5zIHsqfVxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcihzZWxmKSB7XG4gICAgICAgICAgICBpZiAoIXNlbGYuZG9jRGF0YSkge1xuICAgICAgICAgICAgICAgIHJldHVybiBudWxsO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgaWYgKCFzZWxmLmRvY0RhdGEuZG9rICYmIHRoaXMucHJvcHMuaGlzdG9yeSkge1xuICAgICAgICAgICAgICAgIHNlbGYuZG9jRGF0YS5kb2sgPSB0aGlzLnByb3BzLmhpc3RvcnkubG9jYXRpb24uc3RhdGUuZG9rUHJvcElkO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdEb2t1bWVudCAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdkb2snLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LWRvaycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5kb2tcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChTZWxlY3QsIHsgdGl0bGU6ICdLb3JyLiBrb250bzogJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna29udG8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYnM6ICdrb250b2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHNlbGYubGlic1sna29udG9kJ10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5rb250byxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIXNlbGYuc3RhdGUuZWRpdGVkLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2tvbnRvJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xsSWQ6ICdrb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnS0JNLmtvbnRvOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrYm1rb250bycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbGliczogJ2tvbnRvZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogc2VsZi5saWJzWydrb250b2QnXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmtibWtvbnRvLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAna2Jta29udG8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGxJZDogJ2tvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdTZWxnaXR1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnc2VsZycsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd0ZXh0YXJlYS1zZWxnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5zZWxnIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCB9KVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChUZXh0QXJlYSwgeyB0aXRsZTogJ011dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ211dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubXV1ZCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQgfSlcbiAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIFByb2plY3Q7XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5Qcm9qZWN0LnByb3BUeXBlcyA9IHtcbiAgICBkb2NJZDogUHJvcFR5cGVzLm51bWJlcixcbiAgICBpbml0RGF0YTogUHJvcFR5cGVzLm9iamVjdCxcbiAgICB1c2VyRGF0YTogUHJvcFR5cGVzLm9iamVjdFxufTtcblxuUHJvamVjdC5kZWZhdWx0UHJvcHMgPSB7XG4gICAgaW5pdERhdGE6IHt9LFxuICAgIHVzZXJEYXRhOiB7fVxufTtcbm1vZHVsZS5leHBvcnRzID0gUHJvamVjdDtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvZG9rcHJvcHMvZG9jdW1lbnQvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyOTJcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBkb2NSb3c6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAncm93J1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsdWUnXHJcbiAgICAgICAgKi9cbiAgICB9LFxuICAgIGRvY0NvbHVtbjoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nLFxuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIHllbGxvdycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgd2lkdGg6ICc1MCUnXG4gICAgfSxcbiAgICBkb2M6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJ1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJyb3duJ1xyXG4gICAgICAgICovXG4gICAgfVxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvZG9rcHJvcHMvZG9jdW1lbnQvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyOTNcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xuXG52YXIgRG9jdW1lbnRUZW1wbGF0ZSA9IHJlcXVpcmUoJy4vLi4vLi4vZG9jdW1lbnRUZW1wbGF0ZS9pbmRleC5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBUZXh0QXJlYSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvdGV4dC1hcmVhL3RleHQtYXJlYS5qc3gnKSxcbiAgICBzdHlsZXMgPSByZXF1aXJlKCcuL3N0eWxlcycpO1xuXG4vKipcclxuICog0JrQu9Cw0YHRgSDRgNC10LDQu9C40LfRg9C10YIg0LTQvtC60YPQvNC10L3RgiDRgdC/0YDQsNCy0L7Rh9C90LjQutCwINC/0YDQuNC30L3QsNC60L7Qsi5cclxuICovXG5cbnZhciBVc2VyID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKFVzZXIsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIFVzZXIocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIFVzZXIpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChVc2VyLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoVXNlcikpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCksXG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZVxuICAgICAgICB9O1xuICAgICAgICBfdGhpcy5yZW5kZXJlciA9IF90aGlzLnJlbmRlcmVyLmJpbmQoX3RoaXMpO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKFVzZXIsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFRlbXBsYXRlLCB7IGRvY0lkOiB0aGlzLnN0YXRlLmRvY0lkLFxuICAgICAgICAgICAgICAgIHJlZjogJ2RvY3VtZW50JyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6ICdVU0VSSUQnLFxuICAgICAgICAgICAgICAgIG1vZHVsZTogdGhpcy5wcm9wcy5tb2R1bGUsXG4gICAgICAgICAgICAgICAgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgcmVuZGVyZXI6IHRoaXMucmVuZGVyZXJcbiAgICAgICAgICAgIH0pO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0JzQtdGC0L7QtCDQstC10YDQvdC10YIg0LrQsNGB0YLQvtC80L3Ri9C5INC60L7QvNC/0L7QvdC10L3RglxyXG4gICAgICAgICAqIEBwYXJhbSBzZWxmXHJcbiAgICAgICAgICogQHJldHVybnMgeyp9XHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcmVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcmVyKHNlbGYpIHtcbiAgICAgICAgICAgIGlmICghc2VsZi5kb2NEYXRhKSB7XG4gICAgICAgICAgICAgICAgcmV0dXJuIG51bGw7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdLYXN1dGFqYSB0dW5udXM6ICAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrYXN1dGFqYScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQta2FzdXRhamEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEua2FzdXRhamEgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ05pbWk6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2FtZXRuaWsnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LWFtZXRuaWsnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5hbWV0bmlrIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdFbWFpbDogJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnZW1haWwnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LWVtYWlsJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIXNlbGYuc3RhdGUuZWRpdGVkLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuZW1haWwgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ1NtdHA6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3NtdHAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXNtdHAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5zbXRwIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdQb3J0OiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdwb3J0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1wb3J0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIXNlbGYuc3RhdGUuZWRpdGVkLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEucG9ydCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnRW1haWwga2FzdXRhamE6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3VzZXInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXVzZXInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS51c2VyIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdFbWFpbCBwYXJvb2w6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3Bhc3MnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXBhc3MnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5wYXNzIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdNdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdtdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3RleHRhcmVhLW11dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLm11dWQgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIXNlbGYuc3RhdGUuZWRpdGVkIH0pXG4gICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBVc2VyO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuVXNlci5wcm9wVHlwZXMgPSB7XG4gICAgZG9jSWQ6IFByb3BUeXBlcy5udW1iZXIsXG4gICAgaW5pdERhdGE6IFByb3BUeXBlcy5vYmplY3Rcbn07XG5cblVzZXIuZGVmYXVsdFByb3BzID0ge1xuICAgIGluaXREYXRhOiB7fVxufTtcblxubW9kdWxlLmV4cG9ydHMgPSBVc2VyO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy91c2VyaWQvZG9jdW1lbnQvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAyOTRcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IHtcbiAgICBkb2NSb3c6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAncm93J1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsdWUnXHJcbiAgICAgICAgKi9cbiAgICB9LFxuICAgIGRvY0NvbHVtbjoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nLFxuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIHllbGxvdycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgd2lkdGg6ICc1MCUnXG4gICAgfSxcbiAgICBkb2M6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJ1xuICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJyb3duJ1xyXG4gICAgICAgICovXG4gICAgfVxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvdXNlcmlkL2RvY3VtZW50L3N0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMjk1XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIERvY3VtZW50UmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3VtZW50cy9kb2N1bWVudHMuanN4Jyk7XG52YXIgQnRuR2V0WG1sID0gcmVxdWlyZSgnLi8uLi8uLi9jb21wb25lbnRzL2J1dHRvbi1yZWdpc3Rlci9idXR0b24tdGFzay9pbmRleC5qc3gnKTtcbnZhciBUb29sYmFyQ29udGFpbmVyID0gcmVxdWlyZSgnLi8uLi8uLi9jb21wb25lbnRzL3Rvb2xiYXItY29udGFpbmVyL3Rvb2xiYXItY29udGFpbmVyLmpzeCcpO1xuXG52YXIgc3R5bGVzID0gcmVxdWlyZSgnLi9zdHlsZXMnKTtcbnZhciBET0NfVFlQRV9JRCA9ICdJTkYzJztcbnZhciBEb2NDb250ZXh0ID0gcmVxdWlyZSgnLi8uLi8uLi9kb2MtY29udGV4dC5qcycpO1xuXG4vKipcclxuICog0JrQu9Cw0YHRgSDRgNC10LDQu9C40LfRg9C10YIg0LTQvtC60YPQvNC10L3RgiDRgdC/0YDQsNCy0L7Rh9C90LjQutCwINC/0YDQuNC30L3QsNC60L7Qsi5cclxuICovXG5cbnZhciBEb2N1bWVudHMgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoRG9jdW1lbnRzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBEb2N1bWVudHMocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIERvY3VtZW50cyk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKERvY3VtZW50cy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKERvY3VtZW50cykpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5vbkNsaWNrSGFuZGxlciA9IF90aGlzLm9uQ2xpY2tIYW5kbGVyLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5yZW5kZXJlciA9IF90aGlzLnJlbmRlcmVyLmJpbmQoX3RoaXMpO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKERvY3VtZW50cywgW3tcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50UmVnaXN0ZXIsIHsgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICBtb2R1bGU6IHRoaXMucHJvcHMubW9kdWxlLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6IERPQ19UWVBFX0lELFxuICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMsXG4gICAgICAgICAgICAgICAgcmVuZGVyOiB0aGlzLnJlbmRlcmVyIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcihzZWxmKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICBUb29sYmFyQ29udGFpbmVyLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChCdG5HZXRYbWwsIHtcbiAgICAgICAgICAgICAgICAgICAgdmFsdWU6ICdTYWFtYSBYTUwgZmFpbCcsXG4gICAgICAgICAgICAgICAgICAgIG9uQ2xpY2s6IHRoaXMub25DbGlja0hhbmRsZXIsXG4gICAgICAgICAgICAgICAgICAgIHJlZjogJ2J0bi1nZXRYbWwnXG4gICAgICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cblxuICAgICAgICAvL2hhbmRsZXIg0LTQu9GPINGB0L7QsdGL0YLQuNGPINC60LvQuNC6INC90LAg0LrQvdC+0L/QutCw0YUg0L/QsNC90LXQu9C4XG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ29uQ2xpY2tIYW5kbGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIG9uQ2xpY2tIYW5kbGVyKGV2ZW50KSB7XG4gICAgICAgICAgICB2YXIgRG9jID0gdGhpcy5yZWZzWydyZWdpc3RlciddO1xuXG4gICAgICAgICAgICBpZiAoRG9jLmdyaWREYXRhICYmIERvYy5ncmlkRGF0YS5sZW5ndGgpIHtcbiAgICAgICAgICAgICAgICAvL9C00LXQu9Cw0LXQvCDRgNC10LTQsNC50YDQtdC60YIg0L3QsCDQutC+0L3RhNC40LPRg9GA0LDRhtC40Y5cbiAgICAgICAgICAgICAgICB2YXIgc3FsV2hlcmUgPSBEb2Muc3RhdGUuc3FsV2hlcmU7XG4gICAgICAgICAgICAgICAgdmFyIHVybCA9ICcvcmVwb3J0cy9pbmYzLycgKyBEb2NDb250ZXh0LnVzZXJEYXRhLnV1aWQ7XG4gICAgICAgICAgICAgICAgdmFyIHBhcmFtcyA9IGVuY29kZVVSSUNvbXBvbmVudCgnJyArIHNxbFdoZXJlKTtcbiAgICAgICAgICAgICAgICB3aW5kb3cub3Blbih1cmwgKyAnLycgKyBwYXJhbXMpO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBEb2Muc2V0U3RhdGUoe1xuICAgICAgICAgICAgICAgICAgICB3YXJuaW5nOiAnTWl0dGUgw7xodGVnaSBJTkYgdGVlbnVzZWQgbGVpZG51bScsIC8vINGB0YLRgNC+0LrQsCDQuNC30LLQtdGJ0LXQvdC40LlcbiAgICAgICAgICAgICAgICAgICAgd2FybmluZ1R5cGU6ICdub3RWYWxpZCdcblxuICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIERvY3VtZW50cztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gRG9jdW1lbnRzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9pbmYzL2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMjk2XG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgZ3JpZDoge1xuICAgICAgICBtYWluVGFibGU6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfSxcbiAgICAgICAgaGVhZGVyVGFibGU6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfSxcblxuICAgICAgICBncmlkQ29udGFpbmVyOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH1cblxuICAgIH1cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2luZjMvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyOTdcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgRG9jdW1lbnRSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jdW1lbnRzL2RvY3VtZW50cy5qc3gnKTtcbnZhciBJbnB1dE51bWJlciA9IHJlcXVpcmUoJy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtbnVtYmVyL2lucHV0LW51bWJlci5qc3gnKTtcbnZhciBnZXRTdW0gPSByZXF1aXJlKCcuLy4uLy4uLy4uL2xpYnMvZ2V0U3VtJyk7XG5cbnZhciBzdHlsZXMgPSByZXF1aXJlKCcuL3N0eWxlcycpO1xudmFyIERPQ19UWVBFX0lEID0gJ0xBUFNfS09LS1VWT1RURSc7XG5cbi8qKlxyXG4gKiDQmtC70LDRgdGBINGA0LXQsNC70LjQt9GD0LXRgiDQtNC+0LrRg9C80LXQvdGCINGB0L/RgNCw0LLQvtGH0L3QuNC60LAg0L/RgNC40LfQvdCw0LrQvtCyLlxyXG4gKi9cblxudmFyIERvY3VtZW50cyA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhEb2N1bWVudHMsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIERvY3VtZW50cyhwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgRG9jdW1lbnRzKTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoRG9jdW1lbnRzLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoRG9jdW1lbnRzKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgc3VtbWE6IDAsXG4gICAgICAgICAgICB0YXN1dHVkOiAwLFxuICAgICAgICAgICAgamFhazogMFxuICAgICAgICB9O1xuXG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoRG9jdW1lbnRzLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50UmVnaXN0ZXIsIHsgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSA/IHRoaXMucHJvcHMuaGlzdG9yeSA6IG51bGwsXG4gICAgICAgICAgICAgICAgICAgIG1vZHVsZTogdGhpcy5wcm9wcy5tb2R1bGUsXG4gICAgICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICAgICAgZG9jVHlwZUlkOiBET0NfVFlQRV9JRCxcbiAgICAgICAgICAgICAgICAgICAgc3R5bGU6IHN0eWxlcyxcbiAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiB0aGlzLnJlbmRlcmVyIH0pLFxuICAgICAgICAgICAgICAgICc7JyxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7IHRpdGxlOiAnQXJ2ZSBzdW1tYSBrb2trdTonLFxuICAgICAgICAgICAgICAgICAgICBuYW1lOiAnc3VtbWFfa29ra3UnLFxuICAgICAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLnRvdGFsLFxuICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1zdW1tYScsXG4gICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIodGhpcy5zdGF0ZS5zdW1tYSkudG9GaXhlZCgyKSB8fCAwLFxuICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogdHJ1ZSB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7IHRpdGxlOiAnSlxceEU0XFx4RTRrIGtva2t1OicsXG4gICAgICAgICAgICAgICAgICAgIG5hbWU6ICdqYWFrX2tva2t1JyxcbiAgICAgICAgICAgICAgICAgICAgc3R5bGU6IHN0eWxlcy50b3RhbCxcbiAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtamFhaycsXG4gICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIodGhpcy5zdGF0ZS5qYWFrKS50b0ZpeGVkKDIpIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlIH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgdGl0bGU6ICdUYXN1dHVkIGtva2t1OicsXG4gICAgICAgICAgICAgICAgICAgIG5hbWU6ICd0YXN1dHVkX2tva2t1JyxcbiAgICAgICAgICAgICAgICAgICAgc3R5bGU6IHN0eWxlcy50b3RhbCxcbiAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtdGFzdXR1ZCcsXG4gICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIodGhpcy5zdGF0ZS50YXN1dHVkKS50b0ZpeGVkKDIpIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlIH0pXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcihzZWxmKSB7XG4gICAgICAgICAgICB2YXIgc3VtbWEgPSBzZWxmLmdyaWREYXRhID8gZ2V0U3VtKHNlbGYuZ3JpZERhdGEsICdzdW1tYScpIDogMDtcbiAgICAgICAgICAgIHZhciB0YXN1dHVkID0gc2VsZi5ncmlkRGF0YSA/IGdldFN1bShzZWxmLmdyaWREYXRhLCAndGFzdXR1ZCcpIDogMDtcbiAgICAgICAgICAgIHZhciBqYWFrID0gc2VsZi5ncmlkRGF0YSA/IGdldFN1bShzZWxmLmdyaWREYXRhLCAnamFhaycpIDogMDtcbiAgICAgICAgICAgIGlmIChzdW1tYSkge1xuICAgICAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyBzdW1tYTogc3VtbWEsIHRhc3V0dWQ6IHRhc3V0dWQsIGphYWs6IGphYWsgfSk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KCdkaXYnLCBudWxsKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBEb2N1bWVudHM7XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5tb2R1bGUuZXhwb3J0cyA9IERvY3VtZW50cztcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvY2hpbGRfc3VtbWFyeS9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDI5OFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9LFxuICAgIHRvdGFsOiB7XG4gICAgICAgIHdpZHRoOiAnYXV0bydcbiAgICB9XG5cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2NoaWxkX3N1bW1hcnkvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAyOTlcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgRG9jdW1lbnRSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jdW1lbnRzL2RvY3VtZW50cy5qc3gnKTtcbnZhciBCdG5HZXRDc3YgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi10YXNrL2luZGV4LmpzeCcpO1xudmFyIFRvb2xiYXJDb250YWluZXIgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvdG9vbGJhci1jb250YWluZXIvdG9vbGJhci1jb250YWluZXIuanN4Jyk7XG52YXIgSW5wdXROdW1iZXIgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2lucHV0LW51bWJlci9pbnB1dC1udW1iZXIuanN4Jyk7XG52YXIgZ2V0U3VtID0gcmVxdWlyZSgnLi8uLi8uLi8uLi9saWJzL2dldFN1bScpO1xuXG52YXIgRG9jQ29udGV4dCA9IHJlcXVpcmUoJy4vLi4vLi4vZG9jLWNvbnRleHQuanMnKTtcblxudmFyIHN0eWxlcyA9IHJlcXVpcmUoJy4vc3R5bGVzJyk7XG52YXIgRE9DX1RZUEVfSUQgPSAnQVJWRURfS09PRElfSkFSR0knO1xuXG4vKipcclxuICog0JrQu9Cw0YHRgSDRgNC10LDQu9C40LfRg9C10YIg0LTQvtC60YPQvNC10L3RgiDRgdC/0YDQsNCy0L7Rh9C90LjQutCwINC/0YDQuNC30L3QsNC60L7Qsi5cclxuICovXG5cbnZhciBEb2N1bWVudHMgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoRG9jdW1lbnRzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBEb2N1bWVudHMocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIERvY3VtZW50cyk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKERvY3VtZW50cy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKERvY3VtZW50cykpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIHN1bW1hOiAwXG4gICAgICAgIH07XG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLm9uQ2xpY2tIYW5kbGVyID0gX3RoaXMub25DbGlja0hhbmRsZXIuYmluZChfdGhpcyk7XG5cbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2N1bWVudHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRSZWdpc3RlciwgeyBpbml0RGF0YTogdGhpcy5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnByb3BzLm1vZHVsZSxcbiAgICAgICAgICAgICAgICAgICAgcmVmOiAncmVnaXN0ZXInLFxuICAgICAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6IERPQ19UWVBFX0lELFxuICAgICAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLFxuICAgICAgICAgICAgICAgICAgICByZW5kZXI6IHRoaXMucmVuZGVyZXIgfSksXG4gICAgICAgICAgICAgICAgJzsnLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgdGl0bGU6ICdTdW1tYSBrb2trdTonLFxuICAgICAgICAgICAgICAgICAgICBuYW1lOiAnc3VtbWFfa29ra3UnLFxuICAgICAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLnRvdGFsLFxuICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1zdW1tYScsXG4gICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIodGhpcy5zdGF0ZS5zdW1tYSkudG9GaXhlZCgyKSB8fCAwLFxuICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogdHJ1ZSB9KVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgdmFyIHN1bW1hID0gc2VsZi5ncmlkRGF0YSA/IGdldFN1bShzZWxmLmdyaWREYXRhLCAnc3VtbWEnKSA6IDA7XG4gICAgICAgICAgICBpZiAoc3VtbWEpIHtcbiAgICAgICAgICAgICAgICB0aGlzLnNldFN0YXRlKHsgc3VtbWE6IHN1bW1hIH0pO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICBUb29sYmFyQ29udGFpbmVyLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChCdG5HZXRDc3YsIHtcbiAgICAgICAgICAgICAgICAgICAgdmFsdWU6ICdTYWFtYSBDU1YgZmFpbCcsXG4gICAgICAgICAgICAgICAgICAgIG9uQ2xpY2s6IHRoaXMub25DbGlja0hhbmRsZXIsXG4gICAgICAgICAgICAgICAgICAgIHNob3dEYXRlOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgcmVmOiAnYnRuLWdldGNzdidcbiAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8vaGFuZGxlciDQtNC70Y8g0YHQvtCx0YvRgtC40Y8g0LrQu9C40Log0L3QsCDQutC90L7Qv9C60LDRhSDQv9Cw0L3QtdC70LhcblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnb25DbGlja0hhbmRsZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gb25DbGlja0hhbmRsZXIoZXZlbnQpIHtcbiAgICAgICAgICAgIHZhciBEb2MgPSB0aGlzLnJlZnNbJ3JlZ2lzdGVyJ107XG5cbiAgICAgICAgICAgIGlmIChEb2MuZ3JpZERhdGEgJiYgRG9jLmdyaWREYXRhLmxlbmd0aCkge1xuICAgICAgICAgICAgICAgIC8v0LTQtdC70LDQtdC8INGA0LXQtNCw0LnRgNC10LrRgiDQvdCwINC60L7QvdGE0LjQs9GD0YDQsNGG0LjRjlxuICAgICAgICAgICAgICAgIHZhciBzcWxXaGVyZSA9IERvYy5zdGF0ZS5zcWxXaGVyZTtcbiAgICAgICAgICAgICAgICB2YXIgdXJsID0gJy9yZXBvcnRzL2FydmVkX2tvb2RpX2phcmdpLycgKyBEb2NDb250ZXh0LnVzZXJEYXRhLnV1aWQ7XG4gICAgICAgICAgICAgICAgdmFyIHBhcmFtcyA9IGVuY29kZVVSSUNvbXBvbmVudCgnJyArIHNxbFdoZXJlKTtcbiAgICAgICAgICAgICAgICB3aW5kb3cub3Blbih1cmwgKyAnLycgKyBwYXJhbXMpO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBEb2Muc2V0U3RhdGUoe1xuICAgICAgICAgICAgICAgICAgICB3YXJuaW5nOiAnTWl0dGUgw7xodGVnaSBraXJqZWQgbGVpZG51ZCcsIC8vINGB0YLRgNC+0LrQsCDQuNC30LLQtdGJ0LXQvdC40LlcbiAgICAgICAgICAgICAgICAgICAgd2FybmluZ1R5cGU6ICdub3RWYWxpZCdcblxuICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIERvY3VtZW50cztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gRG9jdW1lbnRzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9hcnZlZF9rb29kaV9qYXJnaS9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDMwMFxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICc5NSUnXG4gICAgICAgIH1cblxuICAgIH0sXG4gICAgdG90YWw6IHtcbiAgICAgICAgd2lkdGg6ICdhdXRvJ1xuICAgIH1cblxufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvYXJ2ZWRfa29vZGlfamFyZ2kvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAzMDFcbi8vIG1vZHVsZSBjaHVua3MgPSAwIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgRG9jdW1lbnRSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jdW1lbnRzL2RvY3VtZW50cy5qc3gnKTtcbnZhciBCdG5HZXRYbWwgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi10YXNrL2luZGV4LmpzeCcpO1xudmFyIFRvb2xiYXJDb250YWluZXIgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvdG9vbGJhci1jb250YWluZXIvdG9vbGJhci1jb250YWluZXIuanN4Jyk7XG5cbnZhciBzdHlsZXMgPSByZXF1aXJlKCcuL3N0eWxlcycpO1xudmFyIERPQ19UWVBFX0lEID0gJ1NBTERPX0pBX0tBSVZFJztcbnZhciBEb2NDb250ZXh0ID0gcmVxdWlyZSgnLi8uLi8uLi9kb2MtY29udGV4dC5qcycpO1xuXG4vKipcclxuICog0JrQu9Cw0YHRgSDRgNC10LDQu9C40LfRg9C10YIg0LTQvtC60YPQvNC10L3RgiDRgdC/0YDQsNCy0L7Rh9C90LjQutCwINC/0YDQuNC30L3QsNC60L7Qsi5cclxuICovXG5cbnZhciBEb2N1bWVudHMgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoRG9jdW1lbnRzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBEb2N1bWVudHMocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIERvY3VtZW50cyk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKERvY3VtZW50cy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKERvY3VtZW50cykpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5vbkNsaWNrSGFuZGxlciA9IF90aGlzLm9uQ2xpY2tIYW5kbGVyLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5yZW5kZXJlciA9IF90aGlzLnJlbmRlcmVyLmJpbmQoX3RoaXMpO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKERvY3VtZW50cywgW3tcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50UmVnaXN0ZXIsIHsgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICBtb2R1bGU6IHRoaXMucHJvcHMubW9kdWxlLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6IERPQ19UWVBFX0lELFxuICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMsXG4gICAgICAgICAgICAgICAgcmVuZGVyOiB0aGlzLnJlbmRlcmVyIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgIFRvb2xiYXJDb250YWluZXIsXG4gICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEJ0bkdldFhtbCwge1xuICAgICAgICAgICAgICAgICAgICB2YWx1ZTogJ1NhYW1hIFhNTCBmYWlsJyxcbiAgICAgICAgICAgICAgICAgICAgb25DbGljazogdGhpcy5vbkNsaWNrSGFuZGxlcixcbiAgICAgICAgICAgICAgICAgICAgc2hvd0RhdGU6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICByZWY6ICdidG4tZ2V0WG1sJ1xuICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG5cbiAgICAgICAgLy9oYW5kbGVyINC00LvRjyDRgdC+0LHRi9GC0LjRjyDQutC70LjQuiDQvdCwINC60L3QvtC/0LrQsNGFINC/0LDQvdC10LvQuFxuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdvbkNsaWNrSGFuZGxlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBvbkNsaWNrSGFuZGxlcigpIHtcbiAgICAgICAgICAgIHZhciBEb2MgPSB0aGlzLnJlZnNbJ3JlZ2lzdGVyJ107XG5cbiAgICAgICAgICAgIGlmIChEb2MuZ3JpZERhdGEgJiYgRG9jLmdyaWREYXRhLmxlbmd0aCkge1xuICAgICAgICAgICAgICAgIC8v0LTQtdC70LDQtdC8INGA0LXQtNCw0LnRgNC10LrRgiDQvdCwINC60L7QvdGE0LjQs9GD0YDQsNGG0LjRjlxuICAgICAgICAgICAgICAgIHZhciBzcWxXaGVyZSA9IERvYy5zdGF0ZS5zcWxXaGVyZTtcbiAgICAgICAgICAgICAgICB2YXIgdXJsID0gJy9yZXBvcnRzL3NhbGRvX2phX2thaXZlLycgKyBEb2NDb250ZXh0LnVzZXJEYXRhLnV1aWQ7XG4gICAgICAgICAgICAgICAgdmFyIHBhcmFtcyA9IGVuY29kZVVSSUNvbXBvbmVudCgnJyArIHNxbFdoZXJlKTtcbiAgICAgICAgICAgICAgICB2YXIgZmlsdGVyID0gZW5jb2RlVVJJQ29tcG9uZW50KCcnICsgSlNPTi5zdHJpbmdpZnkoRG9jLmZpbHRlckRhdGEpKTtcbiAgICAgICAgICAgICAgICB3aW5kb3cub3Blbih1cmwgKyAnLycgKyBwYXJhbXMgKyAnLycgKyBmaWx0ZXIpO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBEb2Muc2V0U3RhdGUoe1xuICAgICAgICAgICAgICAgICAgICB3YXJuaW5nOiAnTWl0dGUgw7xodGVnaSBraXJqZWQgbGVpZG51ZCcsIC8vINGB0YLRgNC+0LrQsCDQuNC30LLQtdGJ0LXQvdC40LlcbiAgICAgICAgICAgICAgICAgICAgd2FybmluZ1R5cGU6ICdub3RWYWxpZCdcblxuICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIERvY3VtZW50cztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gRG9jdW1lbnRzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9zYWxkb19qYV9rYWl2ZS9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDMwMlxuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9XG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9zYWxkb19qYV9rYWl2ZS9zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDMwM1xuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcbnZhciBEb2N1bWVudFJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2N1bWVudHMvZG9jdW1lbnRzLmpzeCcpO1xudmFyIHN0eWxlcyA9IHJlcXVpcmUoJy4vc3R5bGVzJyk7XG52YXIgRE9DX1RZUEVfSUQgPSAnU0VOVF9ET0NTJztcblxuLyoqXHJcbiAqINCa0LvQsNGB0YEg0YDQtdCw0LvQuNC30YPQtdGCINC00L7QutGD0LzQtdC90YIg0YHQv9GA0LDQstC+0YfQvdC40LrQsCDQv9GA0LjQt9C90LDQutC+0LIuXHJcbiAqL1xuXG52YXIgRG9jdW1lbnRzID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKERvY3VtZW50cywgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gRG9jdW1lbnRzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBEb2N1bWVudHMpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChEb2N1bWVudHMuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihEb2N1bWVudHMpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMucmVuZGVyZXIgPSBfdGhpcy5yZW5kZXJlci5iaW5kKF90aGlzKTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2N1bWVudHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFJlZ2lzdGVyLCB7IGluaXREYXRhOiB0aGlzLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSA/IHRoaXMucHJvcHMuaGlzdG9yeSA6IG51bGwsXG4gICAgICAgICAgICAgICAgbW9kdWxlOiB0aGlzLnByb3BzLm1vZHVsZSxcbiAgICAgICAgICAgICAgICByZWY6ICdyZWdpc3RlcicsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiBET0NfVFlQRV9JRCxcbiAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLFxuICAgICAgICAgICAgICAgIHJlbmRlcjogdGhpcy5yZW5kZXJlciB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICdTYWFkZXR1ZCBkb2t1bWVtbmRpZCdcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gRG9jdW1lbnRzO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxubW9kdWxlLmV4cG9ydHMgPSBEb2N1bWVudHM7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL3NlbnRfZG9jcy9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDMyN1xuLy8gbW9kdWxlIGNodW5rcyA9IDAiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGdyaWQ6IHtcbiAgICAgICAgbWFpblRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG4gICAgICAgIGhlYWRlclRhYmxlOiB7XG4gICAgICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgICAgIH0sXG5cbiAgICAgICAgZ3JpZENvbnRhaW5lcjoge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9XG5cbiAgICB9XG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9zZW50X2RvY3Mvc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAzMjhcbi8vIG1vZHVsZSBjaHVua3MgPSAwIl0sIm1hcHBpbmdzIjoiOzs7Ozs7QUFBQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzlCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2pVQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzdSQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDcERBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDekdBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzdIQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDaEJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDN0ZBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNoQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDdmlCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzVEQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDbEZBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2RBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNuQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUN0U0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDeERBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDalJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ3hEQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUMxRUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2hCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ3REQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDaEJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzdUQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzVEQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDdkdBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNoQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2hIQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDekJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUM1VEE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ3ZEQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzFJQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDekJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDN0lBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUN6QkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUN2RkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2hCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDM0ZBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ3BCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQy9HQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNwQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDekZBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNoQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDeERBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Iiwic291cmNlUm9vdCI6IiJ9