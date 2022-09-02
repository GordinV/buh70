var raama =
webpackJsonp_name_([1],{

/***/ 0:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';var ReactDOM=__webpack_require__(4);var _require=__webpack_require__(5),BrowserRouter=_require.BrowserRouter;var Doc=__webpack_require__(378);initData=JSON.parse(initData);userData=JSON.parse(userData);ReactDOM.hydrate(React.createElement(BrowserRouter,null,React.createElement(Doc,{initData:initData,userData:userData})),document.getElementById('doc'));

/***/ }),

/***/ 378:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(10);
	var PropTypes = __webpack_require__(33);

	var JournalRegister = __webpack_require__(379);
	var JournalDocument = __webpack_require__(196);
	var ArvedeRegister = __webpack_require__(269);
	var ArveDocument = __webpack_require__(273);
	var SorderideRegister = __webpack_require__(288);
	var SorderDocument = __webpack_require__(290);
	var VorderideRegister = __webpack_require__(381);
	var VorderDocument = __webpack_require__(383);
	var SmkRegister = __webpack_require__(276);
	var SmkDocument = __webpack_require__(279);
	var VmkDocument = __webpack_require__(286);
	var VmkRegister = __webpack_require__(284);
	var Menu = __webpack_require__(50);
	var StartMenu = __webpack_require__(86),
	    AsutusRegister = __webpack_require__(300),
	    AsutusDocument = __webpack_require__(302),
	    KontoRegister = __webpack_require__(388),
	    KontoDocument = __webpack_require__(390),
	    NomRegister = __webpack_require__(292),
	    NomDocument = __webpack_require__(294),
	    ProjectRegister = __webpack_require__(392),
	    ProjectDocument = __webpack_require__(394),
	    TunnusRegister = __webpack_require__(296),
	    TunnusDocument = __webpack_require__(298),
	    DocumentLibRegister = __webpack_require__(396),
	    DocumentLibDocument = __webpack_require__(398);

	var Docs = __webpack_require__(396);

	var _require = __webpack_require__(5),
	    Route = _require.Route,
	    withRouter = _require.withRouter;

	var _require2 = __webpack_require__(91),
	    StyleRoot = _require2.StyleRoot;

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

	                     var activeStyle = { backgroundColor: 'lightblue' };
	                     var btnParams = this.prepareParamsForToolbar();

	                     return React.createElement(
	                            StyleRoot,
	                            null,
	                            React.createElement(Route, { path: '/raama',
	                                   render: function render() {
	                                          return React.createElement(Menu, { params: btnParams });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama',
	                                   render: function render(props) {
	                                          return React.createElement(Docs, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/docs',
	                                   render: function render(props) {
	                                          return React.createElement(Docs, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/dok',
	                                   render: function render(props) {
	                                          return React.createElement(Docs, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/arv/:docId', component: ArveDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/arv',
	                                   render: function render(props) {
	                                          return React.createElement(ArvedeRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/asutused/:docId', component: AsutusDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/asutused',
	                                   render: function render(props) {
	                                          return React.createElement(AsutusRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/sorder/:docId', component: SorderDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/sorder',
	                                   render: function render(props) {
	                                          return React.createElement(SorderideRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/vorder/:docId', component: VorderDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/vorder',
	                                   render: function render(props) {
	                                          return React.createElement(VorderideRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/smk/:docId', component: SmkDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/smk',
	                                   render: function render(props) {
	                                          return React.createElement(SmkRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/vmk/:docId', component: VmkDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/vmk',
	                                   render: function render(props) {
	                                          return React.createElement(VmkRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/journal/:docId', component: JournalDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/journal',
	                                   render: function render(props) {
	                                          return React.createElement(JournalRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/kontod/:docId', component: KontoDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/kontod',
	                                   render: function render(props) {
	                                          return React.createElement(KontoRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/nomenclature/:docId', component: NomDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/nomenclature',
	                                   render: function render(props) {
	                                          return React.createElement(NomRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/project/:docId', component: ProjectDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/project',
	                                   render: function render(props) {
	                                          return React.createElement(ProjectRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/tunnus/:docId', component: TunnusDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/tunnus',
	                                   render: function render(props) {
	                                          return React.createElement(TunnusRegister, { history: props.history, initData: _this2.props.initData });
	                                   } }),
	                            React.createElement(Route, { exact: true, path: '/raama/document/:docId', component: DocumentLibDocument }),
	                            React.createElement(Route, { exact: true, path: '/raama/document',
	                                   render: function render(props) {
	                                          return React.createElement(DocumentLibRegister, { history: props.history, initData: _this2.props.initData });
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
	                     return components['TunnusDocument'] = function (props) {
	                            var TunnusDocument = __webpack_require__(298);
	                            return React.createElement(TunnusDocument, props);
	                     };
	              }
	       }]);

	       return App;
	}(React.Component);

	module.exports = App;

/***/ }),

/***/ 379:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(10);
	var DocumentRegister = __webpack_require__(235);
	var styles = __webpack_require__(380);

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
	                ref: 'register',
	                history: this.props.history ? this.props.history : null,
	                docTypeId: 'JOURNAL',
	                style: styles,
	                render: this.renderer });
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer() {
	            return null;
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 380:
/***/ (function(module, exports) {

	'use strict';module.exports={grid:{mainTable:{width:'100%',td:{border:'1px solid lightGrey',display:'table-cell',paddingLeft:'5px'}},headerTable:{width:'100%'},gridContainer:{width:'100%'}}};

/***/ }),

/***/ 381:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(10);
	var DocumentRegister = __webpack_require__(235);
	var styles = __webpack_require__(382);
	var DOC_TYPE_ID = 'vorder';

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
	                ref: 'register',
	                docTypeId: DOC_TYPE_ID,
	                style: styles,
	                render: this.renderer });
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer() {
	            return null;
	        }
	    }]);

	    return Documents;
	}(React.PureComponent);

	module.exports = Documents;

/***/ }),

/***/ 382:
/***/ (function(module, exports) {

	'use strict';module.exports={grid:{mainTable:{width:'100%',td:{border:'1px solid lightGrey',display:'table-cell',paddingLeft:'5px'}},headerTable:{width:'100%'},gridContainer:{width:'100%'}}};

/***/ }),

/***/ 383:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(10);
	var PropTypes = __webpack_require__(33);

	var DocumentTemplate = __webpack_require__(197),
	    InputText = __webpack_require__(219),
	    InputDate = __webpack_require__(217),
	    InputNumber = __webpack_require__(221),
	    DocCommon = __webpack_require__(384),
	    Select = __webpack_require__(215),
	    TextArea = __webpack_require__(226),
	    DataGrid = __webpack_require__(170),
	    DokProp = __webpack_require__(280),
	    relatedDocuments = __webpack_require__(229),
	    ModalPage = __webpack_require__(168),
	    styles = __webpack_require__(387);

	var LIBDOK = 'VORDER',
	    LIBRARIES = ['asutused', 'kontod', 'dokProps', 'tunnus', 'project', 'nomenclature', 'kassa'];

	var now = new Date();

	var Vorder = function (_React$PureComponent) {
	    _inherits(Vorder, _React$PureComponent);

	    function Vorder(props) {
	        _classCallCheck(this, Vorder);

	        var _this = _possibleConstructorReturn(this, (Vorder.__proto__ || Object.getPrototypeOf(Vorder)).call(this, props));

	        _this.state = {
	            loadedData: false,
	            docId: props.docId ? props.docId : Number(props.match.params.docId)
	        };

	        _this.createGridRow = _this.createGridRow.bind(_this);
	        _this.recalcDocSumma = _this.recalcDocSumma.bind(_this);
	        _this.recalcRowSumm = _this.recalcRowSumm.bind(_this);

	        _this.renderer = _this.renderer.bind(_this);
	        _this.gridValidateFields = _this.gridValidateFields.bind(_this);

	        _this.pages = [{ pageName: 'Väljamakse kassaorder' }];
	        return _this;
	    }

	    _createClass(Vorder, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'SORDER',
	                initData: this.props.initData,
	                reload: true,
	                libs: LIBRARIES,
	                pages: this.pages,
	                renderer: this.renderer,
	                createGridRow: this.createGridRow,
	                gridValidator: this.gridValidateFields,
	                recalcDoc: this.recalcDocSumma,
	                focusElement: 'input-number' });
	        }

	        /**
	         * Вернет кастомные компоненты документа
	         * @returns {XML}
	         */

	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            var bpm = self.docData && self.docData.bpm ? self.docData.bpm : [],
	                isEditeMode = self.state.edited;

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
	                    { className: 'div-doc' },
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(
	                            'div',
	                            { style: styles.docColumn },
	                            React.createElement(InputText, { title: 'Number',
	                                name: 'number',
	                                value: String(self.docData.number) || '',
	                                ref: 'input-number',
	                                onChange: self.handleInputChange,
	                                readOnly: !isEditeMode }),
	                            React.createElement(InputDate, { title: 'Kuup\xE4ev ',
	                                name: 'kpv',
	                                value: self.docData.kpv,
	                                ref: 'input-kpv',
	                                onChange: self.handleInputChange,
	                                readOnly: !isEditeMode }),
	                            React.createElement(Select, { title: 'Kassa',
	                                name: 'kassa_id',
	                                libs: 'kassa',
	                                value: self.docData.kassa_id,
	                                data: self.libs['kassa'],
	                                defaultValue: self.docData.kassa || '',
	                                ref: 'select-kassaId',
	                                onChange: self.handleInputChange,
	                                readOnly: !isEditeMode }),
	                            React.createElement(Select, { title: 'Partner',
	                                name: 'asutusid',
	                                data: self.libs['asutused'],
	                                libs: 'asutused',
	                                value: self.docData.asutusid,
	                                defaultValue: self.docData.asutus || '',
	                                onChange: self.handleInputChange,
	                                ref: 'select-asutusId',
	                                readOnly: !isEditeMode }),
	                            React.createElement(InputText, { title: 'Arve nr.',
	                                name: 'arvnr',
	                                value: self.docData.arvnr || '',
	                                ref: 'input-arvnr',
	                                onChange: self.handleInputChange,
	                                readOnly: true }),
	                            React.createElement(InputText, { title: 'Dokument ',
	                                name: 'dokument',
	                                value: self.docData.dokument || '',
	                                ref: 'input-dokument',
	                                onChange: self.handleInputChange,
	                                readOnly: !isEditeMode })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docColumn },
	                            React.createElement(DokProp, { title: 'Konteerimine: ',
	                                name: 'doklausid',
	                                libs: 'dokProps',
	                                value: self.docData.doklausid,
	                                defaultValue: self.docData.dokprop || '',
	                                ref: 'dokprop',
	                                onChange: self.handleInputChange,
	                                readOnly: !isEditeMode })
	                        )
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(TextArea, { title: 'Nimi',
	                            name: 'nimi',
	                            ref: 'textarea-nimi',
	                            value: self.docData.nimi || '',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditeMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(TextArea, { title: 'Aadress',
	                            name: 'aadress',
	                            ref: 'textarea-aadress',
	                            value: self.docData.aadress || '',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditeMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(TextArea, { title: 'Alus',
	                            name: 'alus',
	                            ref: 'textarea-alus',
	                            value: self.docData.alus || '',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditeMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(DataGrid, { source: 'details',
	                            gridData: self.docData.gridData,
	                            gridColumns: self.docData.gridConfig,
	                            showToolBar: isEditeMode,
	                            handleGridRow: self.handleGridRow,
	                            handleGridBtnClick: self.handleGridBtnClick,
	                            style: styles.grid.headerTable,
	                            readOnly: !isEditeMode,
	                            ref: 'data-grid' })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(InputText, { title: 'Summa: ',
	                            name: 'summa',
	                            ref: 'input-summa',
	                            value: String(self.docData.summa || 0),
	                            width: 'auto',
	                            disabled: true
	                        })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(TextArea, { title: 'M\xE4rkused',
	                            name: 'muud',
	                            ref: 'textarea-muud',
	                            value: self.docData.muud || '',
	                            onChange: self.handleInputChange,
	                            readOnly: !isEditeMode })
	                    ),
	                    self.state.gridRowEdit ? this.createGridRow(self) : null
	                )
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

	            var nomData = [];

	            nomData = self.libs['nomenclature'].filter(function (lib) {
	                if (!lib.dok || lib.dok === LIBDOK) return lib;
	            });

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
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(Select, { title: 'Teenus',
	                                name: 'nomid',
	                                libs: 'nomenclature',
	                                data: nomData,
	                                value: row.nomid,
	                                defaultValue: row.kood || '',
	                                collId: 'id',
	                                ref: 'nomid',
	                                placeholder: 'Teenuse kood',
	                                onChange: self.handleGridRowChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Summa: ',
	                                name: 'summa',
	                                value: Number(row.summa) || 0,
	                                bindData: false,
	                                ref: 'summa',
	                                onChange: self.handleGridRowInput })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(Select, { title: 'Korr. konto',
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
	                            React.createElement(Select, { title: 'Tunnus:',
	                                name: 'tunnus',
	                                data: self.libs['tunnus'],
	                                value: row.tunnus || '',
	                                ref: 'tunnus',
	                                collId: 'kood',
	                                onChange: self.handleGridRowChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(Select, { title: 'Project:',
	                                name: 'proj',
	                                data: self.libs['project'],
	                                value: row.proj || '',
	                                ref: 'project',
	                                collId: 'kood',
	                                onChange: self.handleGridRowChange })
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
	         * перерасчет итоговой суммы документа
	         */

	    }, {
	        key: 'recalcDocSumma',
	        value: function recalcDocSumma() {
	            var doc = this.refs['document'];
	            doc.docData['summa'] = 0;
	            doc.docData.gridData.forEach(function (row) {
	                doc.docData['summa'] += Number(row['summa']);
	            });
	        }

	        /**
	         * подставит код операции
	         */

	    }, {
	        key: 'recalcRowSumm',
	        value: function recalcRowSumm() {
	            var doc = this.refs['document'];

	            if (!Object.keys(doc.gridRowData).length) {
	                return;
	            }

	            //подставим наименование услогу

	            var nomDataName = doc.libs['nomenclature'].filter(function (lib) {
	                if (lib.id === doc.gridRowData['nomid']) return lib;
	            });

	            if (doc.gridRowData['nomid']) {
	                doc.gridRowData['kood'] = nomDataName[0].kood;
	                doc.gridRowData['nimetus'] = nomDataName[0].name;
	            }
	        }

	        /**
	         * валидатор для строки грида
	         * @param gridRowData строка грида
	         * @returns {string}
	         */

	    }, {
	        key: 'gridValidateFields',
	        value: function gridValidateFields() {
	            var warning = '';
	            var doc = this.refs['document'];
	            if (doc && doc.gridRowData) {

	                // только после проверки формы на валидность
	                if (doc.gridRowData && !doc.gridRowData['nomid']) warning = warning + ' Код операции';
	                if (!doc.gridRowData['summa']) warning = warning + ' Сумма';

	                this.recalcRowSumm();
	                this.recalcDocSumma('summa');
	            }
	            return warning;
	        }
	    }]);

	    return Vorder;
	}(React.PureComponent);

	Vorder.propTypes = {
	    docId: PropTypes.number,
	    initData: PropTypes.object,
	    userData: PropTypes.object
	};

	Vorder.defaultProps = {
	    initData: {},
	    userData: {}
	};

	module.exports = Vorder;

/***/ }),

/***/ 384:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(33);

	var React = __webpack_require__(10),
	    InputText = __webpack_require__(219),
	    InputDate = __webpack_require__(385),
	    styles = __webpack_require__(386);

	var DocCommon = function (_React$PureComponent) {
	    _inherits(DocCommon, _React$PureComponent);

	    function DocCommon(props) {
	        _classCallCheck(this, DocCommon);

	        var _this = _possibleConstructorReturn(this, (DocCommon.__proto__ || Object.getPrototypeOf(DocCommon)).call(this, props));

	        _this.state = {
	            readOnly: props.readOnly
	        };
	        return _this;
	    }

	    _createClass(DocCommon, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(
	                'div',
	                { ref: 'wrapper', style: styles.wrapper },
	                React.createElement(InputText, { ref: 'id',
	                    title: 'Id',
	                    name: 'id',
	                    value: String(this.props.data.id),
	                    disabled: true,
	                    width: '75%' }),
	                React.createElement(InputDate, { ref: 'created',
	                    title: 'Created',
	                    name: 'created',
	                    value: this.props.data.created,
	                    disabled: true,
	                    width: '75%' }),
	                React.createElement(InputDate, { ref: 'lastupdate',
	                    title: 'Updated',
	                    name: 'lastupdate',
	                    value: this.props.data.lastupdate,
	                    disabled: true,
	                    width: '75%' }),
	                React.createElement(InputText, { ref: 'status',
	                    title: 'Status',
	                    name: 'status',
	                    value: this.props.data.status,
	                    disabled: true,
	                    width: '75%' })
	            );
	        }

	        /*
	            componentWillReceiveProps(nextProps) {
	                this.forceUpdate();
	            }
	        
	            // will update state if props changed
	            static getDerivedStateFromProps(nextProps, prevState) {
	                    return {nextProps};
	            }
	        */

	    }]);

	    return DocCommon;
	}(React.PureComponent);

	DocCommon.propTypes = {
	    readOnly: PropTypes.bool,
	    data: PropTypes.object.isRequired
	};

	DocCommon.defaultProps = {
	    readOnly: true,
	    data: []
	};

	module.exports = DocCommon;

/***/ }),

/***/ 385:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(33);
	var radium = __webpack_require__(91);

	var React = __webpack_require__(10),
	    styles = __webpack_require__(218);

	var currentDate = new Date().toLocaleDateString();

	var InputDateTime = function (_React$PureComponent) {
	    _inherits(InputDateTime, _React$PureComponent);

	    function InputDateTime(props) {
	        _classCallCheck(this, InputDateTime);

	        var _this = _possibleConstructorReturn(this, (InputDateTime.__proto__ || Object.getPrototypeOf(InputDateTime)).call(this, props));

	        _this.state = {
	            value: props.value || '',
	            readOnly: props.readOnly
	        };
	        _this.onChange = _this.onChange.bind(_this);
	        return _this;
	    }

	    _createClass(InputDateTime, [{
	        key: 'componentWillReceiveProps',
	        value: function componentWillReceiveProps(nextProps) {
	            this.setState({ value: nextProps.value, readOnly: nextProps.readOnly });
	        }
	    }, {
	        key: 'onChange',
	        value: function onChange(e) {
	            var fieldValue = e.target.value,
	                validation = this.validate(fieldValue);

	            if (fieldValue == null) {
	                // если значение нул, то пусть будет nul
	                validation = true;
	            }

	            if (validation) {
	                this.setState({ value: fieldValue });

	                if (this.props.onChange) {
	                    // если задан обработчик, вернем его
	                    this.props.onChange(this.props.name, fieldValue);
	                }
	            }
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var inputPlaceHolder = this.props.placeholder || this.props.title,
	                inputStyle = Object.assign({}, styles.input, this.props.width ? { width: this.props.width } : {}, this.state.readOnly ? styles.readOnly : {});

	            return React.createElement(
	                'div',
	                { style: styles.wrapper },
	                React.createElement(
	                    'label',
	                    { style: styles.label, htmlFor: this.props.name, ref: 'label' },
	                    this.props.title
	                ),
	                React.createElement('input', { type: 'datetime',
	                    style: styles.input,
	                    name: this.props.name,
	                    ref: 'input',
	                    value: this.state.value,
	                    readOnly: this.state.readOnly,
	                    title: this.props.title,
	                    pattern: this.props.pattern,
	                    placeholder: inputPlaceHolder,
	                    min: this.props.min,
	                    max: this.props.max,
	                    onChange: this.onChange,
	                    disabled: this.props.disabled
	                })
	            );
	        }
	    }, {
	        key: 'validate',
	        value: function validate(value) {
	            var result = true;

	            // проверка на мин , мах
	            if (this.props.min && this.props.max && value) {
	                var dateValue = new Date(value);
	                result = dateValue > this.props.min && dateValue < this.props.max;
	            }

	            return result;
	        }

	        /**
	         * установит фокус на элементы
	         */

	    }, {
	        key: 'focus',
	        value: function focus() {
	            this.refs['input'].focus();
	        }
	    }]);

	    return InputDateTime;
	}(React.PureComponent);

	InputDateTime.propTypes = {
	    name: PropTypes.string.isRequired,
	    value: PropTypes.string,
	    min: PropTypes.string,
	    max: PropTypes.string,
	    readOnly: PropTypes.bool,
	    disabled: PropTypes.bool,
	    valid: PropTypes.bool,
	    pattern: PropTypes.string,
	    width: PropTypes.string,
	    title: PropTypes.string,
	    placeholder: PropTypes.string
	};

	InputDateTime.defaultProps = {
	    readOnly: false,
	    disabled: false,
	    valid: true,
	    value: String(currentDate),
	    title: ''
	};

	module.exports = radium(InputDateTime);

/***/ }),

/***/ 386:
/***/ (function(module, exports) {

	'use strict';module.exports={wrapper:{display:'flex',flexDirection:'row',width:'100%',justifyContent:'flex-start'}};

/***/ }),

/***/ 387:
/***/ (function(module, exports) {

	'use strict';module.exports={docRow:{display:'flex',flexDirection:'row'/*
	        border: '1px solid blue'
	*/},docColumn:{display:'flex',flexDirection:'column',/*
	        border: '1px solid yellow',
	*/width:'50%'},doc:{display:'flex',flexDirection:'column'/*
	        border: '1px solid brown'
	*/},gridRow:{border:'1px solid black',backgroundColor:'white',position:'relative',margin:'10% 30% 10% 30%',width:'auto',opacity:'1',top:'100px'},docToolbarWarning:{float:'left',backgroundColor:'red',margin:'10px'},grid:{mainTable:{width:'100%'},headerTable:{width:'100%'},gridContainer:{width:'100%'}}};

/***/ }),

/***/ 388:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(10);
	var Documents = __webpack_require__(235);
	var styles = __webpack_require__(389);
	var DOC_TYPE_ID = 'kontod';

	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Kontod = function (_React$PureComponent) {
	    _inherits(Kontod, _React$PureComponent);

	    function Kontod(props) {
	        _classCallCheck(this, Kontod);

	        return _possibleConstructorReturn(this, (Kontod.__proto__ || Object.getPrototypeOf(Kontod)).call(this, props));
	    }

	    _createClass(Kontod, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(Documents, { initData: this.props.initData,
	                history: this.props.history ? this.props.history : null,
	                ref: 'register',
	                docTypeId: DOC_TYPE_ID,
	                style: styles,
	                render: this.renderer });
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer() {
	            return null;
	        }
	    }]);

	    return Kontod;
	}(React.PureComponent);

	module.exports = Kontod;

/***/ }),

/***/ 389:
/***/ (function(module, exports) {

	'use strict';module.exports={grid:{mainTable:{width:'100%',td:{border:'1px solid lightGrey',display:'table-cell',paddingLeft:'5px'}},headerTable:{width:'100%'},gridContainer:{width:'100%'}}};

/***/ }),

/***/ 390:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(10);
	var PropTypes = __webpack_require__(33);

	var DocumentTemplate = __webpack_require__(197),
	    InputText = __webpack_require__(219),
	    InputDate = __webpack_require__(217),
	    Select = __webpack_require__(215),
	    TextArea = __webpack_require__(226),
	    styles = __webpack_require__(391);

	var KONTO_TYYP = [{ id: 1, kood: "SD", name: "SD" }, { id: 2, kood: "SK", name: "SK" }, { id: 3, kood: "D", name: "D" }, { id: 4, kood: "K", name: "K" }];

	var Kontod = function (_React$PureComponent) {
	    _inherits(Kontod, _React$PureComponent);

	    function Kontod(props) {
	        _classCallCheck(this, Kontod);

	        var _this = _possibleConstructorReturn(this, (Kontod.__proto__ || Object.getPrototypeOf(Kontod)).call(this, props));

	        _this.state = {
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            loadedData: false
	        };

	        _this.renderer = _this.renderer.bind(_this);
	        return _this;
	    }

	    _createClass(Kontod, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'KONTOD',
	                history: this.props.history ? this.props.history : null,
	                initData: this.props.initData,
	                renderer: this.renderer,
	                focusElement: 'input-kood'
	            });
	        }
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
	                    React.createElement(InputText, { title: 'Kood ',
	                        name: 'kood',
	                        ref: 'input-kood',
	                        readOnly: !self.state.edited,
	                        value: self.docData.kood || '',
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputText, { title: 'Nimetus ',
	                        name: 'nimetus',
	                        ref: 'input-nimetus',
	                        readOnly: !self.state.edited,
	                        value: self.docData.nimetus || '',
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(Select, { title: 'Konto t\xFC\xFCp',
	                        name: 'tyyp',
	                        data: KONTO_TYYP,
	                        value: self.docData.tyyp || 0,
	                        defaultValue: self.docData.konto_tyyp,
	                        ref: 'select-tyyp',
	                        btnDelete: self.state.edited,
	                        onChange: self.handleInputChange,
	                        readOnly: !self.state.edited })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputDate, { title: 'Kehtiv kuni:',
	                        name: 'valid',
	                        value: self.docData.valid || '',
	                        ref: 'input-valid',
	                        readOnly: !self.state.edited,
	                        onChange: self.handleInputChange })
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

	    return Kontod;
	}(React.PureComponent);

	Kontod.propTypes = {
	    docId: PropTypes.number,
	    initData: PropTypes.object,
	    userData: PropTypes.object
	};

	Kontod.defaultProps = {
	    initData: {},
	    userData: {}
	};
	module.exports = Kontod;

/***/ }),

/***/ 391:
/***/ (function(module, exports) {

	'use strict';module.exports={docRow:{display:'flex',flexDirection:'row'/*
	        border: '1px solid blue'
	*/},docColumn:{display:'flex',flexDirection:'column',/*
	        border: '1px solid yellow',
	*/width:'50%'},doc:{display:'flex',flexDirection:'column'/*
	        border: '1px solid brown'
	*/}};

/***/ }),

/***/ 392:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(10);
	var Documents = __webpack_require__(235);
	var styles = __webpack_require__(393);
	var DOC_TYPE_ID = 'project';
	/**
	 * Класс реализует документ справочника признаков.
	 */

	var Project = function (_React$PureComponent) {
	    _inherits(Project, _React$PureComponent);

	    function Project(props) {
	        _classCallCheck(this, Project);

	        return _possibleConstructorReturn(this, (Project.__proto__ || Object.getPrototypeOf(Project)).call(this, props));
	    }

	    _createClass(Project, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(Documents, { initData: this.props.initData,
	                userData: this.props.userData,
	                history: this.props.history ? this.props.history : null,
	                ref: 'register',
	                btnEditClick: this.btnEditClick,
	                docTypeId: DOC_TYPE_ID,
	                style: styles,
	                render: this.renderer });
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer() {
	            return null;
	        }
	    }]);

	    return Project;
	}(React.PureComponent);

	module.exports = Project;

/***/ }),

/***/ 393:
/***/ (function(module, exports) {

	'use strict';module.exports={grid:{mainTable:{width:'100%',td:{border:'1px solid lightGrey',display:'table-cell',paddingLeft:'5px'}},headerTable:{width:'100%'},gridContainer:{width:'100%'}}};

/***/ }),

/***/ 394:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(10);
	var PropTypes = __webpack_require__(33);

	var DocumentTemplate = __webpack_require__(197),
	    InputText = __webpack_require__(219),
	    TextArea = __webpack_require__(226),
	    styles = __webpack_require__(395);

	var Project = function (_React$PureComponent) {
	    _inherits(Project, _React$PureComponent);

	    function Project(props) {
	        _classCallCheck(this, Project);

	        var _this = _possibleConstructorReturn(this, (Project.__proto__ || Object.getPrototypeOf(Project)).call(this, props));

	        _this.state = {
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            loadedData: false
	        };
	        _this.renderer = _this.renderer.bind(_this);

	        return _this;
	    }

	    _createClass(Project, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'PROJECT',
	                history: this.props.history,
	                initData: this.props.initData,
	                renderer: this.renderer,
	                focusElement: 'input-kood'
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
	                    React.createElement(InputText, { title: 'Kood ',
	                        name: 'kood',
	                        ref: 'input-kood',
	                        readOnly: !self.state.edited,
	                        value: self.docData.kood,
	                        onChange: self.handleInputChange })
	                ),
	                React.createElement(
	                    'div',
	                    { style: styles.docRow },
	                    React.createElement(InputText, { title: 'Nimetus ',
	                        name: 'nimetus',
	                        ref: 'input-nimetus',
	                        readOnly: !self.state.edited,
	                        value: self.docData.nimetus,
	                        onChange: self.handleInputChange })
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

/***/ 395:
/***/ (function(module, exports) {

	'use strict';module.exports={docRow:{display:'flex',flexDirection:'row'/*
	        border: '1px solid blue'
	*/},docColumn:{display:'flex',flexDirection:'column',/*
	        border: '1px solid yellow',
	*/width:'50%'},doc:{display:'flex',flexDirection:'column'/*
	        border: '1px solid brown'
	*/}};

/***/ }),

/***/ 396:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var React = __webpack_require__(10);
	var Documents = __webpack_require__(235);
	var styles = __webpack_require__(397);

	/**
	 * Класс реализует справочник документов пользователя.
	 */

	var Docs = function (_React$PureComponent) {
	    _inherits(Docs, _React$PureComponent);

	    function Docs(props) {
	        _classCallCheck(this, Docs);

	        var _this = _possibleConstructorReturn(this, (Docs.__proto__ || Object.getPrototypeOf(Docs)).call(this, props));

	        _this.gridData = props.initData.result.data;
	        return _this;
	    }

	    _createClass(Docs, [{
	        key: 'render',
	        value: function render() {
	            var docTypeId = this.props.initData.docTypeId;

	            return React.createElement(Documents, { initData: this.props.initData,
	                history: this.props.history ? this.props.history : null,
	                module: this.props.module,
	                docTypeId: docTypeId,
	                ref: 'register',
	                style: styles,
	                render: this.renderer });
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer() {
	            return null;
	        }
	    }]);

	    return Docs;
	}(React.PureComponent);

	module.exports = Docs;

/***/ }),

/***/ 397:
/***/ (function(module, exports) {

	'use strict';module.exports={grid:{mainTable:{width:'100%'},headerTable:{width:'100%'},gridContainer:{width:'100%'}}};

/***/ }),

/***/ 398:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(33);
	var React = __webpack_require__(10);

	var DocumentTemplate = __webpack_require__(197),
	    InputText = __webpack_require__(219),
	    Select = __webpack_require__(215),
	    TextArea = __webpack_require__(226),
	    styles = __webpack_require__(399),
	    DOCUMENT_TYPES = [{ id: 1, kood: 'document', name: 'document' }, { id: 2, kood: 'library', name: 'library' }];

	/**
	 * Реализует документ справочника Типы документов
	 */

	var Document = function (_React$PureComponent) {
	    _inherits(Document, _React$PureComponent);

	    function Document(props) {
	        _classCallCheck(this, Document);

	        var _this = _possibleConstructorReturn(this, (Document.__proto__ || Object.getPrototypeOf(Document)).call(this, props));

	        _this.state = {
	            docId: props.docId ? props.docId : Number(props.match.params.docId),
	            loadedData: false
	        };
	        _this.renderer = _this.renderer.bind(_this);
	        return _this;
	    }

	    _createClass(Document, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentTemplate, { docId: this.state.docId,
	                ref: 'document',
	                docTypeId: 'DOK',
	                initData: this.props.initData,
	                renderer: this.renderer });
	        }
	    }, {
	        key: 'renderer',
	        value: function renderer(self) {
	            if (!self.docData) {
	                return null;
	            }

	            return React.createElement(
	                'div',
	                null,
	                React.createElement(
	                    'div',
	                    { style: styles.doc },
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(InputText, { title: 'Kood ',
	                            name: 'kood',
	                            ref: 'input-kood',
	                            value: self.docData.kood,
	                            readOnly: !self.state.edited,
	                            onChange: self.handleInputChange })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(InputText, { title: 'Nimetus ',
	                            name: 'nimetus',
	                            ref: 'input-nimetus',
	                            value: self.docData.nimetus,
	                            readOnly: !self.state.edited,
	                            onChange: self.handleInputChange })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(Select, { title: 'T\xFC\xFCp:',
	                            name: 'type',
	                            data: DOCUMENT_TYPES,
	                            collId: 'kood',
	                            value: self.docData.type,
	                            defaultValue: self.docData.type,
	                            ref: 'select-type',
	                            btnDelete: !self.state.edited,
	                            onChange: self.handleInputChange,
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
	                )
	            );
	        }
	    }]);

	    return Document;
	}(React.PureComponent);

	Document.propTypes = {
	    docId: PropTypes.number,
	    initData: PropTypes.object,
	    userData: PropTypes.object
	};

	Document.defaultProps = {
	    initData: {},
	    userData: {}
	};

	module.exports = Document;

/***/ }),

/***/ 399:
/***/ (function(module, exports) {

	'use strict';module.exports={docRow:{display:'flex',flexDirection:'row'/*
	        border: '1px solid blue'
	*/},docColumn:{display:'flex',flexDirection:'column',/*
	        border: '1px solid yellow',
	*/width:'50%'},doc:{display:'flex',flexDirection:'column'/*
	        border: '1px solid brown'
	*/}};

/***/ })

});
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoicmFhbWEuanMiLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9yYWFtYS5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9tb2R1bGVzL3JhYW1hLmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2pvdXJuYWwvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3Mvam91cm5hbC9qb3VybmFsLXJlZ2lzdGVyLXN0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3ZvcmRlci9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy92b3JkZXIvdm9yZGVyLXJlZ2lzdGVyLXN0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3ZvcmRlci9kb2N1bWVudC9pbmRleC5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvY29tcG9uZW50cy9kb2MtY29tbW9uL2RvYy1jb21tb24uanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2NvbXBvbmVudHMvaW5wdXQtZGF0ZXRpbWUvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2NvbXBvbmVudHMvZG9jLWNvbW1vbi9kb2MtY29tbW9uLXN0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3ZvcmRlci9kb2N1bWVudC92b3JkZXItc3R5bGUuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9rb250b2QvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3Mva29udG9kL2tvbnRvZC1yZWdpc3Rlci5zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9rb250b2QvZG9jdW1lbnQvaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3Mva29udG9kL2RvY3VtZW50L2tvbnRvZC1zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9wcm9qZWN0L2luZGV4LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3Byb2plY3QvcHJvamVjdC1yZWdpc3Rlci1zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9wcm9qZWN0L2RvY3VtZW50L2luZGV4LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL3Byb2plY3QvZG9jdW1lbnQvcHJvamVjdC1zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9kb2svaW5kZXguanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvZG9rL2RvY3MtcmVnaXN0ZXItc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvZG9rL2RvY3VtZW50L2luZGV4LmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2Rvay9kb2N1bWVudC9kb2N1bWVudC1zdHlsZXMuanMiXSwic291cmNlc0NvbnRlbnQiOlsiJ3VzZSBzdHJpY3QnO3ZhciBSZWFjdERPTT1yZXF1aXJlKCdyZWFjdC1kb20nKTt2YXIgX3JlcXVpcmU9cmVxdWlyZSgncmVhY3Qtcm91dGVyLWRvbScpLEJyb3dzZXJSb3V0ZXI9X3JlcXVpcmUuQnJvd3NlclJvdXRlcjt2YXIgRG9jPXJlcXVpcmUoJy4uL2Zyb250ZW5kL21vZHVsZXMvcmFhbWEuanN4Jyk7aW5pdERhdGE9SlNPTi5wYXJzZShpbml0RGF0YSk7dXNlckRhdGE9SlNPTi5wYXJzZSh1c2VyRGF0YSk7UmVhY3RET00uaHlkcmF0ZShSZWFjdC5jcmVhdGVFbGVtZW50KEJyb3dzZXJSb3V0ZXIsbnVsbCxSZWFjdC5jcmVhdGVFbGVtZW50KERvYyx7aW5pdERhdGE6aW5pdERhdGEsdXNlckRhdGE6dXNlckRhdGF9KSksZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoJ2RvYycpKTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL3JhYW1hLmpzXG4vLyBtb2R1bGUgaWQgPSAwXG4vLyBtb2R1bGUgY2h1bmtzID0gMSIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIFByb3BUeXBlcyA9IHJlcXVpcmUoJ3Byb3AtdHlwZXMnKTtcblxudmFyIEpvdXJuYWxSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9qb3VybmFsL2luZGV4LmpzeCcpO1xudmFyIEpvdXJuYWxEb2N1bWVudCA9IHJlcXVpcmUoJy4uL2RvY3Mvam91cm5hbC9kb2N1bWVudC9pbmRleC5qc3gnKTtcbnZhciBBcnZlZGVSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9hcnYvaW5kZXguanN4Jyk7XG52YXIgQXJ2ZURvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2Fydi9kb2N1bWVudC9pbmRleC5qc3gnKTtcbnZhciBTb3JkZXJpZGVSZWdpc3RlciA9IHJlcXVpcmUoJy4vLi4vZG9jcy9zb3JkZXIvaW5kZXguanN4Jyk7XG52YXIgU29yZGVyRG9jdW1lbnQgPSByZXF1aXJlKCcuLy4uL2RvY3Mvc29yZGVyL2RvY3VtZW50L2luZGV4LmpzeCcpO1xudmFyIFZvcmRlcmlkZVJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL3ZvcmRlci9pbmRleC5qc3gnKTtcbnZhciBWb3JkZXJEb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy92b3JkZXIvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG52YXIgU21rUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3Mvc21rL2luZGV4LmpzeCcpO1xudmFyIFNta0RvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL3Ntay9kb2N1bWVudC9pbmRleC5qc3gnKTtcbnZhciBWbWtEb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy92bWsvZG9jdW1lbnQvaW5kZXguanN4Jyk7XG52YXIgVm1rUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3Mvdm1rL2luZGV4LmpzeCcpO1xudmFyIE1lbnUgPSByZXF1aXJlKCcuLy4uL2NvbXBvbmVudHMvbWVudS10b29sYmFyL21lbnUtdG9vbGJhci5qc3gnKTtcbnZhciBTdGFydE1lbnUgPSByZXF1aXJlKCcuLy4uL2NvbXBvbmVudHMvc3RhcnQtbWVudS9zdGFydC1tZW51LmpzeCcpLFxuICAgIEFzdXR1c1JlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL2FzdXR1c2VkL2luZGV4LmpzeCcpLFxuICAgIEFzdXR1c0RvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2FzdXR1c2VkL2RvY3VtZW50L2luZGV4LmpzeCcpLFxuICAgIEtvbnRvUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3Mva29udG9kL2luZGV4LmpzeCcpLFxuICAgIEtvbnRvRG9jdW1lbnQgPSByZXF1aXJlKCcuLy4uL2RvY3Mva29udG9kL2RvY3VtZW50L2luZGV4LmpzeCcpLFxuICAgIE5vbVJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL25vbWVuY2xhdHVyZS9pbmRleC5qc3gnKSxcbiAgICBOb21Eb2N1bWVudCA9IHJlcXVpcmUoJy4vLi4vZG9jcy9ub21lbmNsYXR1cmUvZG9jdW1lbnQvaW5kZXguanN4JyksXG4gICAgUHJvamVjdFJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL3Byb2plY3QvaW5kZXguanN4JyksXG4gICAgUHJvamVjdERvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL3Byb2plY3QvZG9jdW1lbnQvaW5kZXguanN4JyksXG4gICAgVHVubnVzUmVnaXN0ZXIgPSByZXF1aXJlKCcuLy4uL2RvY3MvdHVubnVzL2luZGV4LmpzeCcpLFxuICAgIFR1bm51c0RvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL3R1bm51cy9kb2N1bWVudC9pbmRleC5qc3gnKSxcbiAgICBEb2N1bWVudExpYlJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2NzL2Rvay9pbmRleC5qc3gnKSxcbiAgICBEb2N1bWVudExpYkRvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL2Rvay9kb2N1bWVudC9pbmRleC5qc3gnKTtcblxudmFyIERvY3MgPSByZXF1aXJlKCcuLy4uL2RvY3MvZG9rL2luZGV4LmpzeCcpO1xuXG52YXIgX3JlcXVpcmUgPSByZXF1aXJlKCdyZWFjdC1yb3V0ZXItZG9tJyksXG4gICAgUm91dGUgPSBfcmVxdWlyZS5Sb3V0ZSxcbiAgICB3aXRoUm91dGVyID0gX3JlcXVpcmUud2l0aFJvdXRlcjtcblxudmFyIF9yZXF1aXJlMiA9IHJlcXVpcmUoJ3JhZGl1bScpLFxuICAgIFN0eWxlUm9vdCA9IF9yZXF1aXJlMi5TdHlsZVJvb3Q7XG5cbnZhciBBcHAgPSBmdW5jdGlvbiAoX1JlYWN0JENvbXBvbmVudCkge1xuICAgICAgIF9pbmhlcml0cyhBcHAsIF9SZWFjdCRDb21wb25lbnQpO1xuXG4gICAgICAgZnVuY3Rpb24gQXBwKHByb3BzKSB7XG4gICAgICAgICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBBcHApO1xuXG4gICAgICAgICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChBcHAuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihBcHApKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgICAgICAgX3RoaXMucHJlcGFyZVBhcmFtc0ZvclRvb2xiYXIgPSBfdGhpcy5wcmVwYXJlUGFyYW1zRm9yVG9vbGJhci5iaW5kKF90aGlzKTtcbiAgICAgICAgICAgICAgX3RoaXMuY29tcG9uZXRzID0ge307XG4gICAgICAgICAgICAgIF90aGlzLnByZXBhcmVDb21wb25lbnRzKF90aGlzLmNvbXBvbmV0cyk7XG4gICAgICAgICAgICAgIHJldHVybiBfdGhpcztcbiAgICAgICB9XG5cbiAgICAgICBfY3JlYXRlQ2xhc3MoQXBwLCBbe1xuICAgICAgICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgICAgICAgICAgdmFyIF90aGlzMiA9IHRoaXM7XG5cbiAgICAgICAgICAgICAgICAgICAgIHZhciBhY3RpdmVTdHlsZSA9IHsgYmFja2dyb3VuZENvbG9yOiAnbGlnaHRibHVlJyB9O1xuICAgICAgICAgICAgICAgICAgICAgdmFyIGJ0blBhcmFtcyA9IHRoaXMucHJlcGFyZVBhcmFtc0ZvclRvb2xiYXIoKTtcblxuICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgU3R5bGVSb290LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBwYXRoOiAnL3JhYW1hJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChNZW51LCB7IHBhcmFtczogYnRuUGFyYW1zIH0pO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jcywgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LCBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhIH0pO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEvZG9jcycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2NzLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEgfSk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9yYWFtYS9kb2snLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jcywgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LCBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhIH0pO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEvYXJ2Lzpkb2NJZCcsIGNvbXBvbmVudDogQXJ2ZURvY3VtZW50IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEvYXJ2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KEFydmVkZVJlZ2lzdGVyLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEgfSk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9yYWFtYS9hc3V0dXNlZC86ZG9jSWQnLCBjb21wb25lbnQ6IEFzdXR1c0RvY3VtZW50IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEvYXN1dHVzZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQXN1dHVzUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSwgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSB9KTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL3JhYW1hL3NvcmRlci86ZG9jSWQnLCBjb21wb25lbnQ6IFNvcmRlckRvY3VtZW50IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEvc29yZGVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFNvcmRlcmlkZVJlZ2lzdGVyLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEgfSk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9yYWFtYS92b3JkZXIvOmRvY0lkJywgY29tcG9uZW50OiBWb3JkZXJEb2N1bWVudCB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL3JhYW1hL3ZvcmRlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChWb3JkZXJpZGVSZWdpc3RlciwgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LCBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhIH0pO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEvc21rLzpkb2NJZCcsIGNvbXBvbmVudDogU21rRG9jdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9yYWFtYS9zbWsnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU21rUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSwgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSB9KTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL3JhYW1hL3Ztay86ZG9jSWQnLCBjb21wb25lbnQ6IFZta0RvY3VtZW50IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEvdm1rJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFZta1JlZ2lzdGVyLCB7IGhpc3Rvcnk6IHByb3BzLmhpc3RvcnksIGluaXREYXRhOiBfdGhpczIucHJvcHMuaW5pdERhdGEgfSk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0gfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9yYWFtYS9qb3VybmFsLzpkb2NJZCcsIGNvbXBvbmVudDogSm91cm5hbERvY3VtZW50IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEvam91cm5hbCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlbmRlcjogZnVuY3Rpb24gcmVuZGVyKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChKb3VybmFsUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSwgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSB9KTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL3JhYW1hL2tvbnRvZC86ZG9jSWQnLCBjb21wb25lbnQ6IEtvbnRvRG9jdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9yYWFtYS9rb250b2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoS29udG9SZWdpc3RlciwgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LCBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhIH0pO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEvbm9tZW5jbGF0dXJlLzpkb2NJZCcsIGNvbXBvbmVudDogTm9tRG9jdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9yYWFtYS9ub21lbmNsYXR1cmUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoTm9tUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSwgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSB9KTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL3JhYW1hL3Byb2plY3QvOmRvY0lkJywgY29tcG9uZW50OiBQcm9qZWN0RG9jdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9yYWFtYS9wcm9qZWN0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFByb2plY3RSZWdpc3RlciwgeyBoaXN0b3J5OiBwcm9wcy5oaXN0b3J5LCBpbml0RGF0YTogX3RoaXMyLnByb3BzLmluaXREYXRhIH0pO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9IH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUm91dGUsIHsgZXhhY3Q6IHRydWUsIHBhdGg6ICcvcmFhbWEvdHVubnVzLzpkb2NJZCcsIGNvbXBvbmVudDogVHVubnVzRG9jdW1lbnQgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChSb3V0ZSwgeyBleGFjdDogdHJ1ZSwgcGF0aDogJy9yYWFtYS90dW5udXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcihwcm9wcykge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVHVubnVzUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSwgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSB9KTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL3JhYW1hL2RvY3VtZW50Lzpkb2NJZCcsIGNvbXBvbmVudDogRG9jdW1lbnRMaWJEb2N1bWVudCB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFJvdXRlLCB7IGV4YWN0OiB0cnVlLCBwYXRoOiAnL3JhYW1hL2RvY3VtZW50JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIocHJvcHMpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50TGliUmVnaXN0ZXIsIHsgaGlzdG9yeTogcHJvcHMuaGlzdG9yeSwgaW5pdERhdGE6IF90aGlzMi5wcm9wcy5pbml0RGF0YSB9KTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSB9KVxuICAgICAgICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgICAgfVxuICAgICAgIH0sIHtcbiAgICAgICAgICAgICAga2V5OiAncHJlcGFyZVBhcmFtc0ZvclRvb2xiYXInLFxuICAgICAgICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcHJlcGFyZVBhcmFtc0ZvclRvb2xiYXIoKSB7XG4gICAgICAgICAgICAgICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJ0blN0YXJ0OiB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNob3c6IHRydWVcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJ0bkxvZ2luOiB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYnRuQWNjb3VudDoge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgICAgICAgICAgIH07XG4gICAgICAgICAgICAgIH1cbiAgICAgICB9LCB7XG4gICAgICAgICAgICAgIGtleTogJ3ByZXBhcmVDb21wb25lbnRzJyxcbiAgICAgICAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHByZXBhcmVDb21wb25lbnRzKGNvbXBvbmVudHMpIHtcbiAgICAgICAgICAgICAgICAgICAgIHJldHVybiBjb21wb25lbnRzWydUdW5udXNEb2N1bWVudCddID0gZnVuY3Rpb24gKHByb3BzKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFyIFR1bm51c0RvY3VtZW50ID0gcmVxdWlyZSgnLi8uLi9kb2NzL3R1bm51cy9kb2N1bWVudC9pbmRleC5qc3gnKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChUdW5udXNEb2N1bWVudCwgcHJvcHMpO1xuICAgICAgICAgICAgICAgICAgICAgfTtcbiAgICAgICAgICAgICAgfVxuICAgICAgIH1dKTtcblxuICAgICAgIHJldHVybiBBcHA7XG59KFJlYWN0LkNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gQXBwO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvbW9kdWxlcy9yYWFtYS5qc3hcbi8vIG1vZHVsZSBpZCA9IDM3OFxuLy8gbW9kdWxlIGNodW5rcyA9IDEiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcbnZhciBEb2N1bWVudFJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2N1bWVudHMvZG9jdW1lbnRzLmpzeCcpO1xudmFyIHN0eWxlcyA9IHJlcXVpcmUoJy4vam91cm5hbC1yZWdpc3Rlci1zdHlsZXMnKTtcblxuLyoqXHJcbiAqINCa0LvQsNGB0YEg0YDQtdCw0LvQuNC30YPQtdGCINC00L7QutGD0LzQtdC90YIg0YHQv9GA0LDQstC+0YfQvdC40LrQsCDQv9GA0LjQt9C90LDQutC+0LIuXHJcbiAqL1xuXG52YXIgRG9jdW1lbnRzID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKERvY3VtZW50cywgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gRG9jdW1lbnRzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBEb2N1bWVudHMpO1xuXG4gICAgICAgIHJldHVybiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoRG9jdW1lbnRzLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoRG9jdW1lbnRzKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2N1bWVudHMsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFJlZ2lzdGVyLCB7IGluaXREYXRhOiB0aGlzLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBoaXN0b3J5OiB0aGlzLnByb3BzLmhpc3RvcnkgPyB0aGlzLnByb3BzLmhpc3RvcnkgOiBudWxsLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ0pPVVJOQUwnLFxuICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMsXG4gICAgICAgICAgICAgICAgcmVuZGVyOiB0aGlzLnJlbmRlcmVyIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBudWxsO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIERvY3VtZW50cztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gRG9jdW1lbnRzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9qb3VybmFsL2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMzc5XG4vLyBtb2R1bGUgY2h1bmtzID0gMSIsIid1c2Ugc3RyaWN0Jzttb2R1bGUuZXhwb3J0cz17Z3JpZDp7bWFpblRhYmxlOnt3aWR0aDonMTAwJScsdGQ6e2JvcmRlcjonMXB4IHNvbGlkIGxpZ2h0R3JleScsZGlzcGxheTondGFibGUtY2VsbCcscGFkZGluZ0xlZnQ6JzVweCd9fSxoZWFkZXJUYWJsZTp7d2lkdGg6JzEwMCUnfSxncmlkQ29udGFpbmVyOnt3aWR0aDonMTAwJSd9fX07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2pvdXJuYWwvam91cm5hbC1yZWdpc3Rlci1zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDM4MFxuLy8gbW9kdWxlIGNodW5rcyA9IDEiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcbnZhciBEb2N1bWVudFJlZ2lzdGVyID0gcmVxdWlyZSgnLi8uLi9kb2N1bWVudHMvZG9jdW1lbnRzLmpzeCcpO1xudmFyIHN0eWxlcyA9IHJlcXVpcmUoJy4vdm9yZGVyLXJlZ2lzdGVyLXN0eWxlcycpO1xudmFyIERPQ19UWVBFX0lEID0gJ3ZvcmRlcic7XG5cbi8qKlxyXG4gKiDQmtC70LDRgdGBINGA0LXQsNC70LjQt9GD0LXRgiDQtNC+0LrRg9C80LXQvdGCINGB0L/RgNCw0LLQvtGH0L3QuNC60LAg0L/RgNC40LfQvdCw0LrQvtCyLlxyXG4gKi9cblxudmFyIERvY3VtZW50cyA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhEb2N1bWVudHMsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIERvY3VtZW50cyhwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgRG9jdW1lbnRzKTtcblxuICAgICAgICByZXR1cm4gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKERvY3VtZW50cy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKERvY3VtZW50cykpLmNhbGwodGhpcywgcHJvcHMpKTtcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoRG9jdW1lbnRzLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRSZWdpc3RlciwgeyBpbml0RGF0YTogdGhpcy5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICBoaXN0b3J5OiB0aGlzLnByb3BzLmhpc3RvcnkgPyB0aGlzLnByb3BzLmhpc3RvcnkgOiBudWxsLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6IERPQ19UWVBFX0lELFxuICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMsXG4gICAgICAgICAgICAgICAgcmVuZGVyOiB0aGlzLnJlbmRlcmVyIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBudWxsO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIERvY3VtZW50cztcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gRG9jdW1lbnRzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy92b3JkZXIvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAzODFcbi8vIG1vZHVsZSBjaHVua3MgPSAxIiwiJ3VzZSBzdHJpY3QnO21vZHVsZS5leHBvcnRzPXtncmlkOnttYWluVGFibGU6e3dpZHRoOicxMDAlJyx0ZDp7Ym9yZGVyOicxcHggc29saWQgbGlnaHRHcmV5JyxkaXNwbGF5Oid0YWJsZS1jZWxsJyxwYWRkaW5nTGVmdDonNXB4J319LGhlYWRlclRhYmxlOnt3aWR0aDonMTAwJSd9LGdyaWRDb250YWluZXI6e3dpZHRoOicxMDAlJ319fTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3Mvdm9yZGVyL3ZvcmRlci1yZWdpc3Rlci1zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDM4MlxuLy8gbW9kdWxlIGNodW5rcyA9IDEiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcbnZhciBQcm9wVHlwZXMgPSByZXF1aXJlKCdwcm9wLXR5cGVzJyk7XG5cbnZhciBEb2N1bWVudFRlbXBsYXRlID0gcmVxdWlyZSgnLi4vLi4vZG9jdW1lbnRUZW1wbGF0ZS9pbmRleC5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBJbnB1dERhdGUgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LWRhdGUvaW5wdXQtZGF0ZS5qc3gnKSxcbiAgICBJbnB1dE51bWJlciA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtbnVtYmVyL2lucHV0LW51bWJlci5qc3gnKSxcbiAgICBEb2NDb21tb24gPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2RvYy1jb21tb24vZG9jLWNvbW1vbi5qc3gnKSxcbiAgICBTZWxlY3QgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL3NlbGVjdC9zZWxlY3QuanN4JyksXG4gICAgVGV4dEFyZWEgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL3RleHQtYXJlYS90ZXh0LWFyZWEuanN4JyksXG4gICAgRGF0YUdyaWQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2RhdGEtZ3JpZC9kYXRhLWdyaWQuanN4JyksXG4gICAgRG9rUHJvcCA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvZG9jcHJvcC9kb2Nwcm9wLmpzeCcpLFxuICAgIHJlbGF0ZWREb2N1bWVudHMgPSByZXF1aXJlKCcuLi8uLi8uLi9taXhpbi9yZWxhdGVkRG9jdW1lbnRzLmpzeCcpLFxuICAgIE1vZGFsUGFnZSA9IHJlcXVpcmUoJy4vLi4vLi4vLi4vY29tcG9uZW50cy9tb2RhbHBhZ2UvbW9kYWxQYWdlLmpzeCcpLFxuICAgIHN0eWxlcyA9IHJlcXVpcmUoJy4vdm9yZGVyLXN0eWxlJyk7XG5cbnZhciBMSUJET0sgPSAnVk9SREVSJyxcbiAgICBMSUJSQVJJRVMgPSBbJ2FzdXR1c2VkJywgJ2tvbnRvZCcsICdkb2tQcm9wcycsICd0dW5udXMnLCAncHJvamVjdCcsICdub21lbmNsYXR1cmUnLCAna2Fzc2EnXTtcblxudmFyIG5vdyA9IG5ldyBEYXRlKCk7XG5cbnZhciBWb3JkZXIgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoVm9yZGVyLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBWb3JkZXIocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIFZvcmRlcik7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKFZvcmRlci5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKFZvcmRlcikpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIGxvYWRlZERhdGE6IGZhbHNlLFxuICAgICAgICAgICAgZG9jSWQ6IHByb3BzLmRvY0lkID8gcHJvcHMuZG9jSWQgOiBOdW1iZXIocHJvcHMubWF0Y2gucGFyYW1zLmRvY0lkKVxuICAgICAgICB9O1xuXG4gICAgICAgIF90aGlzLmNyZWF0ZUdyaWRSb3cgPSBfdGhpcy5jcmVhdGVHcmlkUm93LmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5yZWNhbGNEb2NTdW1tYSA9IF90aGlzLnJlY2FsY0RvY1N1bW1hLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5yZWNhbGNSb3dTdW1tID0gX3RoaXMucmVjYWxjUm93U3VtbS5iaW5kKF90aGlzKTtcblxuICAgICAgICBfdGhpcy5yZW5kZXJlciA9IF90aGlzLnJlbmRlcmVyLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5ncmlkVmFsaWRhdGVGaWVsZHMgPSBfdGhpcy5ncmlkVmFsaWRhdGVGaWVsZHMuYmluZChfdGhpcyk7XG5cbiAgICAgICAgX3RoaXMucGFnZXMgPSBbeyBwYWdlTmFtZTogJ1bDpGxqYW1ha3NlIGthc3Nhb3JkZXInIH1dO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKFZvcmRlciwgW3tcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50VGVtcGxhdGUsIHsgZG9jSWQ6IHRoaXMuc3RhdGUuZG9jSWQsXG4gICAgICAgICAgICAgICAgcmVmOiAnZG9jdW1lbnQnLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ1NPUkRFUicsXG4gICAgICAgICAgICAgICAgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgcmVsb2FkOiB0cnVlLFxuICAgICAgICAgICAgICAgIGxpYnM6IExJQlJBUklFUyxcbiAgICAgICAgICAgICAgICBwYWdlczogdGhpcy5wYWdlcyxcbiAgICAgICAgICAgICAgICByZW5kZXJlcjogdGhpcy5yZW5kZXJlcixcbiAgICAgICAgICAgICAgICBjcmVhdGVHcmlkUm93OiB0aGlzLmNyZWF0ZUdyaWRSb3csXG4gICAgICAgICAgICAgICAgZ3JpZFZhbGlkYXRvcjogdGhpcy5ncmlkVmFsaWRhdGVGaWVsZHMsXG4gICAgICAgICAgICAgICAgcmVjYWxjRG9jOiB0aGlzLnJlY2FsY0RvY1N1bW1hLFxuICAgICAgICAgICAgICAgIGZvY3VzRWxlbWVudDogJ2lucHV0LW51bWJlcicgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQktC10YDQvdC10YIg0LrQsNGB0YLQvtC80L3Ri9C1INC60L7QvNC/0L7QvdC10L3RgtGLINC00L7QutGD0LzQtdC90YLQsFxyXG4gICAgICAgICAqIEByZXR1cm5zIHtYTUx9XHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcmVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcmVyKHNlbGYpIHtcbiAgICAgICAgICAgIHZhciBicG0gPSBzZWxmLmRvY0RhdGEgJiYgc2VsZi5kb2NEYXRhLmJwbSA/IHNlbGYuZG9jRGF0YS5icG0gOiBbXSxcbiAgICAgICAgICAgICAgICBpc0VkaXRlTW9kZSA9IHNlbGYuc3RhdGUuZWRpdGVkO1xuXG4gICAgICAgICAgICAvLyDRhNC+0YDQvNC40YDRg9C10Lwg0LfQsNCy0LjRgdC40LzQvtGB0YLQuFxuICAgICAgICAgICAgaWYgKHNlbGYuZG9jRGF0YS5yZWxhdGlvbnMpIHtcbiAgICAgICAgICAgICAgICByZWxhdGVkRG9jdW1lbnRzKHNlbGYpO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICB2YXIgZG9jID0gdGhpcy5yZWZzWydkb2N1bWVudCddO1xuICAgICAgICAgICAgdmFyIGxpYnMgPSBkb2MgPyBkb2MubGlicyA6IHt9O1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IGNsYXNzTmFtZTogJ2Rpdi1kb2MnIH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnTnVtYmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ251bWJlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBTdHJpbmcoc2VsZi5kb2NEYXRhLm51bWJlcikgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LW51bWJlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdGVNb2RlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXREYXRlLCB7IHRpdGxlOiAnS3V1cFxceEU0ZXYgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2twdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEua3B2LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1rcHYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRlTW9kZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdCwgeyB0aXRsZTogJ0thc3NhJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2thc3NhX2lkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbGliczogJ2thc3NhJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5rYXNzYV9pZCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogc2VsZi5saWJzWydrYXNzYSddLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHNlbGYuZG9jRGF0YS5rYXNzYSB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LWthc3NhSWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRlTW9kZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdCwgeyB0aXRsZTogJ1BhcnRuZXInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYXN1dHVzaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBzZWxmLmxpYnNbJ2FzdXR1c2VkJ10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYnM6ICdhc3V0dXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuYXN1dHVzaWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlZmF1bHRWYWx1ZTogc2VsZi5kb2NEYXRhLmFzdXR1cyB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3NlbGVjdC1hc3V0dXNJZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0ZU1vZGUgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdBcnZlIG5yLicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdhcnZucicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuYXJ2bnIgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LWFydm5yJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiB0cnVlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnRG9rdW1lbnQgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2Rva3VtZW50JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5kb2t1bWVudCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtZG9rdW1lbnQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRlTW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9rUHJvcCwgeyB0aXRsZTogJ0tvbnRlZXJpbWluZTogJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2Rva2xhdXNpZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYnM6ICdkb2tQcm9wcycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuZG9rbGF1c2lkLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHNlbGYuZG9jRGF0YS5kb2twcm9wIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdkb2twcm9wJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0ZU1vZGUgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChUZXh0QXJlYSwgeyB0aXRsZTogJ05pbWknLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICduaW1pJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd0ZXh0YXJlYS1uaW1pJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLm5pbWkgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRlTW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFRleHRBcmVhLCB7IHRpdGxlOiAnQWFkcmVzcycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2FhZHJlc3MnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3RleHRhcmVhLWFhZHJlc3MnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEuYWFkcmVzcyB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdGVNb2RlIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdBbHVzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYWx1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAndGV4dGFyZWEtYWx1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5hbHVzIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0ZU1vZGUgfSlcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEYXRhR3JpZCwgeyBzb3VyY2U6ICdkZXRhaWxzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBncmlkRGF0YTogc2VsZi5kb2NEYXRhLmdyaWREYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGdyaWRDb2x1bW5zOiBzZWxmLmRvY0RhdGEuZ3JpZENvbmZpZyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzaG93VG9vbEJhcjogaXNFZGl0ZU1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaGFuZGxlR3JpZFJvdzogc2VsZi5oYW5kbGVHcmlkUm93LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRCdG5DbGljazogc2VsZi5oYW5kbGVHcmlkQnRuQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGU6IHN0eWxlcy5ncmlkLmhlYWRlclRhYmxlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0ZU1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnZGF0YS1ncmlkJyB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ1N1bW1hOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdzdW1tYScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtc3VtbWEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBTdHJpbmcoc2VsZi5kb2NEYXRhLnN1bW1hIHx8IDApLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHdpZHRoOiAnYXV0bycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IHRydWVcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdNXFx4RTRya3VzZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdtdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd0ZXh0YXJlYS1tdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLm11dWQgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRlTW9kZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBzZWxmLnN0YXRlLmdyaWRSb3dFZGl0ID8gdGhpcy5jcmVhdGVHcmlkUm93KHNlbGYpIDogbnVsbFxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDRhNC+0YDQvNC40YDRg9C10YIg0L7QsdGK0LXQutGC0Ysg0LzQvtC00LDQu9GM0L3QvtCz0L4g0L7QutC90LAg0YDQtdC00LDQutGC0LjRgNC+0LLQsNC90LjRjyDRgdGC0YDQvtC60Lgg0LPRgNC40LTQsFxyXG4gICAgICAgICAqIEByZXR1cm5zIHtYTUx9XHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2NyZWF0ZUdyaWRSb3cnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gY3JlYXRlR3JpZFJvdyhzZWxmKSB7XG4gICAgICAgICAgICB2YXIgcm93ID0gc2VsZi5ncmlkUm93RGF0YSA/IHNlbGYuZ3JpZFJvd0RhdGEgOiB7fSxcbiAgICAgICAgICAgICAgICB2YWxpZGF0ZU1lc3NhZ2UgPSAnJyxcbiAgICAgICAgICAgICAgICAvLyBzZWxmLnN0YXRlLndhcm5pbmdcbiAgICAgICAgICAgIGJ1dHRvbk9rUmVhZE9ubHkgPSB2YWxpZGF0ZU1lc3NhZ2UubGVuZ3RoID4gMCB8fCAhc2VsZi5zdGF0ZS5jaGVja2VkLFxuICAgICAgICAgICAgICAgIG1vZGFsT2JqZWN0cyA9IFsnYnRuT2snLCAnYnRuQ2FuY2VsJ107XG5cbiAgICAgICAgICAgIGlmIChidXR0b25Pa1JlYWRPbmx5KSB7XG4gICAgICAgICAgICAgICAgLy8g0YPQsdC10YDQtdC8INC60L3QvtC/0LrRgyDQntC6XG4gICAgICAgICAgICAgICAgbW9kYWxPYmplY3RzLnNwbGljZSgwLCAxKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgaWYgKCFyb3cpIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KCdkaXYnLCBudWxsKTtcblxuICAgICAgICAgICAgdmFyIG5vbURhdGEgPSBbXTtcblxuICAgICAgICAgICAgbm9tRGF0YSA9IHNlbGYubGlic1snbm9tZW5jbGF0dXJlJ10uZmlsdGVyKGZ1bmN0aW9uIChsaWIpIHtcbiAgICAgICAgICAgICAgICBpZiAoIWxpYi5kb2sgfHwgbGliLmRvayA9PT0gTElCRE9LKSByZXR1cm4gbGliO1xuICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIHsgY2xhc3NOYW1lOiAnLm1vZGFsUGFnZScgfSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICBNb2RhbFBhZ2UsXG4gICAgICAgICAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIG1vZGFsT2JqZWN0czogbW9kYWxPYmplY3RzLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnbW9kYWxwYWdlLWdyaWQtcm93JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgICAgICBtb2RhbFBhZ2VCdG5DbGljazogc2VsZi5tb2RhbFBhZ2VDbGljayxcbiAgICAgICAgICAgICAgICAgICAgICAgIG1vZGFsUGFnZU5hbWU6ICdSZWEgbGlzYW1pbmUgLyBwYXJhbmRhbWluZScgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyByZWY6ICdncmlkLXJvdy1jb250YWluZXInIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdCwgeyB0aXRsZTogJ1RlZW51cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdub21pZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYnM6ICdub21lbmNsYXR1cmUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBub21EYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogcm93Lm5vbWlkLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHJvdy5rb29kIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xsSWQ6ICdpZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ25vbWlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGxhY2Vob2xkZXI6ICdUZWVudXNlIGtvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVHcmlkUm93Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dE51bWJlciwgeyB0aXRsZTogJ1N1bW1hOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnc3VtbWEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHJvdy5zdW1tYSkgfHwgMCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYmluZERhdGE6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdzdW1tYScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUdyaWRSb3dJbnB1dCB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnS29yci4ga29udG8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna29udG8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBzZWxmLmxpYnNbJ2tvbnRvZCddLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogcm93LmtvbnRvIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdrb250bycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGxJZDogJ2tvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVHcmlkUm93Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChTZWxlY3QsIHsgdGl0bGU6ICdUdW5udXM6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3R1bm51cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHNlbGYubGlic1sndHVubnVzJ10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiByb3cudHVubnVzIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd0dW5udXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xsSWQ6ICdrb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlR3JpZFJvd0NoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnUHJvamVjdDonLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAncHJvaicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHNlbGYubGlic1sncHJvamVjdCddLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogcm93LnByb2ogfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3Byb2plY3QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xsSWQ6ICdrb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlR3JpZFJvd0NoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnc3BhbicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWxpZGF0ZU1lc3NhZ2VcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQv9C10YDQtdGA0LDRgdGH0LXRgiDQuNGC0L7Qs9C+0LLQvtC5INGB0YPQvNC80Ysg0LTQvtC60YPQvNC10L3RgtCwXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlY2FsY0RvY1N1bW1hJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlY2FsY0RvY1N1bW1hKCkge1xuICAgICAgICAgICAgdmFyIGRvYyA9IHRoaXMucmVmc1snZG9jdW1lbnQnXTtcbiAgICAgICAgICAgIGRvYy5kb2NEYXRhWydzdW1tYSddID0gMDtcbiAgICAgICAgICAgIGRvYy5kb2NEYXRhLmdyaWREYXRhLmZvckVhY2goZnVuY3Rpb24gKHJvdykge1xuICAgICAgICAgICAgICAgIGRvYy5kb2NEYXRhWydzdW1tYSddICs9IE51bWJlcihyb3dbJ3N1bW1hJ10pO1xuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQv9C+0LTRgdGC0LDQstC40YIg0LrQvtC0INC+0L/QtdGA0LDRhtC40LhcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVjYWxjUm93U3VtbScsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZWNhbGNSb3dTdW1tKCkge1xuICAgICAgICAgICAgdmFyIGRvYyA9IHRoaXMucmVmc1snZG9jdW1lbnQnXTtcblxuICAgICAgICAgICAgaWYgKCFPYmplY3Qua2V5cyhkb2MuZ3JpZFJvd0RhdGEpLmxlbmd0aCkge1xuICAgICAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgLy/Qv9C+0LTRgdGC0LDQstC40Lwg0L3QsNC40LzQtdC90L7QstCw0L3QuNC1INGD0YHQu9C+0LPRg1xuXG4gICAgICAgICAgICB2YXIgbm9tRGF0YU5hbWUgPSBkb2MubGlic1snbm9tZW5jbGF0dXJlJ10uZmlsdGVyKGZ1bmN0aW9uIChsaWIpIHtcbiAgICAgICAgICAgICAgICBpZiAobGliLmlkID09PSBkb2MuZ3JpZFJvd0RhdGFbJ25vbWlkJ10pIHJldHVybiBsaWI7XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgaWYgKGRvYy5ncmlkUm93RGF0YVsnbm9taWQnXSkge1xuICAgICAgICAgICAgICAgIGRvYy5ncmlkUm93RGF0YVsna29vZCddID0gbm9tRGF0YU5hbWVbMF0ua29vZDtcbiAgICAgICAgICAgICAgICBkb2MuZ3JpZFJvd0RhdGFbJ25pbWV0dXMnXSA9IG5vbURhdGFOYW1lWzBdLm5hbWU7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQstCw0LvQuNC00LDRgtC+0YAg0LTQu9GPINGB0YLRgNC+0LrQuCDQs9GA0LjQtNCwXHJcbiAgICAgICAgICogQHBhcmFtIGdyaWRSb3dEYXRhINGB0YLRgNC+0LrQsCDQs9GA0LjQtNCwXHJcbiAgICAgICAgICogQHJldHVybnMge3N0cmluZ31cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnZ3JpZFZhbGlkYXRlRmllbGRzJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGdyaWRWYWxpZGF0ZUZpZWxkcygpIHtcbiAgICAgICAgICAgIHZhciB3YXJuaW5nID0gJyc7XG4gICAgICAgICAgICB2YXIgZG9jID0gdGhpcy5yZWZzWydkb2N1bWVudCddO1xuICAgICAgICAgICAgaWYgKGRvYyAmJiBkb2MuZ3JpZFJvd0RhdGEpIHtcblxuICAgICAgICAgICAgICAgIC8vINGC0L7Qu9GM0LrQviDQv9C+0YHQu9C1INC/0YDQvtCy0LXRgNC60Lgg0YTQvtGA0LzRiyDQvdCwINCy0LDQu9C40LTQvdC+0YHRgtGMXG4gICAgICAgICAgICAgICAgaWYgKGRvYy5ncmlkUm93RGF0YSAmJiAhZG9jLmdyaWRSb3dEYXRhWydub21pZCddKSB3YXJuaW5nID0gd2FybmluZyArICcg0JrQvtC0INC+0L/QtdGA0LDRhtC40LgnO1xuICAgICAgICAgICAgICAgIGlmICghZG9jLmdyaWRSb3dEYXRhWydzdW1tYSddKSB3YXJuaW5nID0gd2FybmluZyArICcg0KHRg9C80LzQsCc7XG5cbiAgICAgICAgICAgICAgICB0aGlzLnJlY2FsY1Jvd1N1bW0oKTtcbiAgICAgICAgICAgICAgICB0aGlzLnJlY2FsY0RvY1N1bW1hKCdzdW1tYScpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcmV0dXJuIHdhcm5pbmc7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gVm9yZGVyO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuVm9yZGVyLnByb3BUeXBlcyA9IHtcbiAgICBkb2NJZDogUHJvcFR5cGVzLm51bWJlcixcbiAgICBpbml0RGF0YTogUHJvcFR5cGVzLm9iamVjdCxcbiAgICB1c2VyRGF0YTogUHJvcFR5cGVzLm9iamVjdFxufTtcblxuVm9yZGVyLmRlZmF1bHRQcm9wcyA9IHtcbiAgICBpbml0RGF0YToge30sXG4gICAgdXNlckRhdGE6IHt9XG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IFZvcmRlcjtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3Mvdm9yZGVyL2RvY3VtZW50L2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMzgzXG4vLyBtb2R1bGUgY2h1bmtzID0gMSIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpLFxuICAgIElucHV0VGV4dCA9IHJlcXVpcmUoJy4vLi4vaW5wdXQtdGV4dC9pbnB1dC10ZXh0LmpzeCcpLFxuICAgIElucHV0RGF0ZSA9IHJlcXVpcmUoJy4uL2lucHV0LWRhdGV0aW1lL2luZGV4LmpzeCcpLFxuICAgIHN0eWxlcyA9IHJlcXVpcmUoJy4vZG9jLWNvbW1vbi1zdHlsZXMnKTtcblxudmFyIERvY0NvbW1vbiA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhEb2NDb21tb24sIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIERvY0NvbW1vbihwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgRG9jQ29tbW9uKTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoRG9jQ29tbW9uLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoRG9jQ29tbW9uKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgcmVhZE9ubHk6IHByb3BzLnJlYWRPbmx5XG4gICAgICAgIH07XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoRG9jQ29tbW9uLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgeyByZWY6ICd3cmFwcGVyJywgc3R5bGU6IHN0eWxlcy53cmFwcGVyIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgcmVmOiAnaWQnLFxuICAgICAgICAgICAgICAgICAgICB0aXRsZTogJ0lkJyxcbiAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2lkJyxcbiAgICAgICAgICAgICAgICAgICAgdmFsdWU6IFN0cmluZyh0aGlzLnByb3BzLmRhdGEuaWQpLFxuICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgd2lkdGg6ICc3NSUnIH0pLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXREYXRlLCB7IHJlZjogJ2NyZWF0ZWQnLFxuICAgICAgICAgICAgICAgICAgICB0aXRsZTogJ0NyZWF0ZWQnLFxuICAgICAgICAgICAgICAgICAgICBuYW1lOiAnY3JlYXRlZCcsXG4gICAgICAgICAgICAgICAgICAgIHZhbHVlOiB0aGlzLnByb3BzLmRhdGEuY3JlYXRlZCxcbiAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgIHdpZHRoOiAnNzUlJyB9KSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0RGF0ZSwgeyByZWY6ICdsYXN0dXBkYXRlJyxcbiAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdVcGRhdGVkJyxcbiAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2xhc3R1cGRhdGUnLFxuICAgICAgICAgICAgICAgICAgICB2YWx1ZTogdGhpcy5wcm9wcy5kYXRhLmxhc3R1cGRhdGUsXG4gICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICB3aWR0aDogJzc1JScgfSksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgcmVmOiAnc3RhdHVzJyxcbiAgICAgICAgICAgICAgICAgICAgdGl0bGU6ICdTdGF0dXMnLFxuICAgICAgICAgICAgICAgICAgICBuYW1lOiAnc3RhdHVzJyxcbiAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHRoaXMucHJvcHMuZGF0YS5zdGF0dXMsXG4gICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICB3aWR0aDogJzc1JScgfSlcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cblxuICAgICAgICAvKlxyXG4gICAgICAgICAgICBjb21wb25lbnRXaWxsUmVjZWl2ZVByb3BzKG5leHRQcm9wcykge1xyXG4gICAgICAgICAgICAgICAgdGhpcy5mb3JjZVVwZGF0ZSgpO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgXHJcbiAgICAgICAgICAgIC8vIHdpbGwgdXBkYXRlIHN0YXRlIGlmIHByb3BzIGNoYW5nZWRcclxuICAgICAgICAgICAgc3RhdGljIGdldERlcml2ZWRTdGF0ZUZyb21Qcm9wcyhuZXh0UHJvcHMsIHByZXZTdGF0ZSkge1xyXG4gICAgICAgICAgICAgICAgICAgIHJldHVybiB7bmV4dFByb3BzfTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgICovXG5cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gRG9jQ29tbW9uO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuRG9jQ29tbW9uLnByb3BUeXBlcyA9IHtcbiAgICByZWFkT25seTogUHJvcFR5cGVzLmJvb2wsXG4gICAgZGF0YTogUHJvcFR5cGVzLm9iamVjdC5pc1JlcXVpcmVkXG59O1xuXG5Eb2NDb21tb24uZGVmYXVsdFByb3BzID0ge1xuICAgIHJlYWRPbmx5OiB0cnVlLFxuICAgIGRhdGE6IFtdXG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IERvY0NvbW1vbjtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2NvbXBvbmVudHMvZG9jLWNvbW1vbi9kb2MtY29tbW9uLmpzeFxuLy8gbW9kdWxlIGlkID0gMzg0XG4vLyBtb2R1bGUgY2h1bmtzID0gMSIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xudmFyIHJhZGl1bSA9IHJlcXVpcmUoJ3JhZGl1bScpO1xuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpLFxuICAgIHN0eWxlcyA9IHJlcXVpcmUoJy4uL2lucHV0LWRhdGUvaW5wdXQtZGF0ZS1zdHlsZXMnKTtcblxudmFyIGN1cnJlbnREYXRlID0gbmV3IERhdGUoKS50b0xvY2FsZURhdGVTdHJpbmcoKTtcblxudmFyIElucHV0RGF0ZVRpbWUgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoSW5wdXREYXRlVGltZSwgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gSW5wdXREYXRlVGltZShwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgSW5wdXREYXRlVGltZSk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKElucHV0RGF0ZVRpbWUuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihJbnB1dERhdGVUaW1lKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgdmFsdWU6IHByb3BzLnZhbHVlIHx8ICcnLFxuICAgICAgICAgICAgcmVhZE9ubHk6IHByb3BzLnJlYWRPbmx5XG4gICAgICAgIH07XG4gICAgICAgIF90aGlzLm9uQ2hhbmdlID0gX3RoaXMub25DaGFuZ2UuYmluZChfdGhpcyk7XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoSW5wdXREYXRlVGltZSwgW3tcbiAgICAgICAga2V5OiAnY29tcG9uZW50V2lsbFJlY2VpdmVQcm9wcycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBjb21wb25lbnRXaWxsUmVjZWl2ZVByb3BzKG5leHRQcm9wcykge1xuICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IHZhbHVlOiBuZXh0UHJvcHMudmFsdWUsIHJlYWRPbmx5OiBuZXh0UHJvcHMucmVhZE9ubHkgfSk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ29uQ2hhbmdlJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIG9uQ2hhbmdlKGUpIHtcbiAgICAgICAgICAgIHZhciBmaWVsZFZhbHVlID0gZS50YXJnZXQudmFsdWUsXG4gICAgICAgICAgICAgICAgdmFsaWRhdGlvbiA9IHRoaXMudmFsaWRhdGUoZmllbGRWYWx1ZSk7XG5cbiAgICAgICAgICAgIGlmIChmaWVsZFZhbHVlID09IG51bGwpIHtcbiAgICAgICAgICAgICAgICAvLyDQtdGB0LvQuCDQt9C90LDRh9C10L3QuNC1INC90YPQuywg0YLQviDQv9GD0YHRgtGMINCx0YPQtNC10YIgbnVsXG4gICAgICAgICAgICAgICAgdmFsaWRhdGlvbiA9IHRydWU7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIGlmICh2YWxpZGF0aW9uKSB7XG4gICAgICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IHZhbHVlOiBmaWVsZFZhbHVlIH0pO1xuXG4gICAgICAgICAgICAgICAgaWYgKHRoaXMucHJvcHMub25DaGFuZ2UpIHtcbiAgICAgICAgICAgICAgICAgICAgLy8g0LXRgdC70Lgg0LfQsNC00LDQvSDQvtCx0YDQsNCx0L7RgtGH0LjQuiwg0LLQtdGA0L3QtdC8INC10LPQvlxuICAgICAgICAgICAgICAgICAgICB0aGlzLnByb3BzLm9uQ2hhbmdlKHRoaXMucHJvcHMubmFtZSwgZmllbGRWYWx1ZSk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgdmFyIGlucHV0UGxhY2VIb2xkZXIgPSB0aGlzLnByb3BzLnBsYWNlaG9sZGVyIHx8IHRoaXMucHJvcHMudGl0bGUsXG4gICAgICAgICAgICAgICAgaW5wdXRTdHlsZSA9IE9iamVjdC5hc3NpZ24oe30sIHN0eWxlcy5pbnB1dCwgdGhpcy5wcm9wcy53aWR0aCA/IHsgd2lkdGg6IHRoaXMucHJvcHMud2lkdGggfSA6IHt9LCB0aGlzLnN0YXRlLnJlYWRPbmx5ID8gc3R5bGVzLnJlYWRPbmx5IDoge30pO1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMud3JhcHBlciB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdsYWJlbCcsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5sYWJlbCwgaHRtbEZvcjogdGhpcy5wcm9wcy5uYW1lLCByZWY6ICdsYWJlbCcgfSxcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5wcm9wcy50aXRsZVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudCgnaW5wdXQnLCB7IHR5cGU6ICdkYXRldGltZScsXG4gICAgICAgICAgICAgICAgICAgIHN0eWxlOiBzdHlsZXMuaW5wdXQsXG4gICAgICAgICAgICAgICAgICAgIG5hbWU6IHRoaXMucHJvcHMubmFtZSxcbiAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQnLFxuICAgICAgICAgICAgICAgICAgICB2YWx1ZTogdGhpcy5zdGF0ZS52YWx1ZSxcbiAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6IHRoaXMuc3RhdGUucmVhZE9ubHksXG4gICAgICAgICAgICAgICAgICAgIHRpdGxlOiB0aGlzLnByb3BzLnRpdGxlLFxuICAgICAgICAgICAgICAgICAgICBwYXR0ZXJuOiB0aGlzLnByb3BzLnBhdHRlcm4sXG4gICAgICAgICAgICAgICAgICAgIHBsYWNlaG9sZGVyOiBpbnB1dFBsYWNlSG9sZGVyLFxuICAgICAgICAgICAgICAgICAgICBtaW46IHRoaXMucHJvcHMubWluLFxuICAgICAgICAgICAgICAgICAgICBtYXg6IHRoaXMucHJvcHMubWF4LFxuICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5vbkNoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IHRoaXMucHJvcHMuZGlzYWJsZWRcbiAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAndmFsaWRhdGUnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gdmFsaWRhdGUodmFsdWUpIHtcbiAgICAgICAgICAgIHZhciByZXN1bHQgPSB0cnVlO1xuXG4gICAgICAgICAgICAvLyDQv9GA0L7QstC10YDQutCwINC90LAg0LzQuNC9ICwg0LzQsNGFXG4gICAgICAgICAgICBpZiAodGhpcy5wcm9wcy5taW4gJiYgdGhpcy5wcm9wcy5tYXggJiYgdmFsdWUpIHtcbiAgICAgICAgICAgICAgICB2YXIgZGF0ZVZhbHVlID0gbmV3IERhdGUodmFsdWUpO1xuICAgICAgICAgICAgICAgIHJlc3VsdCA9IGRhdGVWYWx1ZSA+IHRoaXMucHJvcHMubWluICYmIGRhdGVWYWx1ZSA8IHRoaXMucHJvcHMubWF4O1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICByZXR1cm4gcmVzdWx0O1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0YPRgdGC0LDQvdC+0LLQuNGCINGE0L7QutGD0YEg0L3QsCDRjdC70LXQvNC10L3RgtGLXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2ZvY3VzJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGZvY3VzKCkge1xuICAgICAgICAgICAgdGhpcy5yZWZzWydpbnB1dCddLmZvY3VzKCk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gSW5wdXREYXRlVGltZTtcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbklucHV0RGF0ZVRpbWUucHJvcFR5cGVzID0ge1xuICAgIG5hbWU6IFByb3BUeXBlcy5zdHJpbmcuaXNSZXF1aXJlZCxcbiAgICB2YWx1ZTogUHJvcFR5cGVzLnN0cmluZyxcbiAgICBtaW46IFByb3BUeXBlcy5zdHJpbmcsXG4gICAgbWF4OiBQcm9wVHlwZXMuc3RyaW5nLFxuICAgIHJlYWRPbmx5OiBQcm9wVHlwZXMuYm9vbCxcbiAgICBkaXNhYmxlZDogUHJvcFR5cGVzLmJvb2wsXG4gICAgdmFsaWQ6IFByb3BUeXBlcy5ib29sLFxuICAgIHBhdHRlcm46IFByb3BUeXBlcy5zdHJpbmcsXG4gICAgd2lkdGg6IFByb3BUeXBlcy5zdHJpbmcsXG4gICAgdGl0bGU6IFByb3BUeXBlcy5zdHJpbmcsXG4gICAgcGxhY2Vob2xkZXI6IFByb3BUeXBlcy5zdHJpbmdcbn07XG5cbklucHV0RGF0ZVRpbWUuZGVmYXVsdFByb3BzID0ge1xuICAgIHJlYWRPbmx5OiBmYWxzZSxcbiAgICBkaXNhYmxlZDogZmFsc2UsXG4gICAgdmFsaWQ6IHRydWUsXG4gICAgdmFsdWU6IFN0cmluZyhjdXJyZW50RGF0ZSksXG4gICAgdGl0bGU6ICcnXG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IHJhZGl1bShJbnB1dERhdGVUaW1lKTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2NvbXBvbmVudHMvaW5wdXQtZGF0ZXRpbWUvaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAzODVcbi8vIG1vZHVsZSBjaHVua3MgPSAxIiwiJ3VzZSBzdHJpY3QnO21vZHVsZS5leHBvcnRzPXt3cmFwcGVyOntkaXNwbGF5OidmbGV4JyxmbGV4RGlyZWN0aW9uOidyb3cnLHdpZHRoOicxMDAlJyxqdXN0aWZ5Q29udGVudDonZmxleC1zdGFydCd9fTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2NvbXBvbmVudHMvZG9jLWNvbW1vbi9kb2MtY29tbW9uLXN0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMzg2XG4vLyBtb2R1bGUgY2h1bmtzID0gMSIsIid1c2Ugc3RyaWN0Jzttb2R1bGUuZXhwb3J0cz17ZG9jUm93OntkaXNwbGF5OidmbGV4JyxmbGV4RGlyZWN0aW9uOidyb3cnLypcclxuICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYmx1ZSdcclxuKi99LGRvY0NvbHVtbjp7ZGlzcGxheTonZmxleCcsZmxleERpcmVjdGlvbjonY29sdW1uJywvKlxyXG4gICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCB5ZWxsb3cnLFxyXG4qL3dpZHRoOic1MCUnfSxkb2M6e2Rpc3BsYXk6J2ZsZXgnLGZsZXhEaXJlY3Rpb246J2NvbHVtbicvKlxyXG4gICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBicm93bidcclxuKi99LGdyaWRSb3c6e2JvcmRlcjonMXB4IHNvbGlkIGJsYWNrJyxiYWNrZ3JvdW5kQ29sb3I6J3doaXRlJyxwb3NpdGlvbjoncmVsYXRpdmUnLG1hcmdpbjonMTAlIDMwJSAxMCUgMzAlJyx3aWR0aDonYXV0bycsb3BhY2l0eTonMScsdG9wOicxMDBweCd9LGRvY1Rvb2xiYXJXYXJuaW5nOntmbG9hdDonbGVmdCcsYmFja2dyb3VuZENvbG9yOidyZWQnLG1hcmdpbjonMTBweCd9LGdyaWQ6e21haW5UYWJsZTp7d2lkdGg6JzEwMCUnfSxoZWFkZXJUYWJsZTp7d2lkdGg6JzEwMCUnfSxncmlkQ29udGFpbmVyOnt3aWR0aDonMTAwJSd9fX07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL3ZvcmRlci9kb2N1bWVudC92b3JkZXItc3R5bGUuanNcbi8vIG1vZHVsZSBpZCA9IDM4N1xuLy8gbW9kdWxlIGNodW5rcyA9IDEiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcbnZhciBEb2N1bWVudHMgPSByZXF1aXJlKCcuLy4uL2RvY3VtZW50cy9kb2N1bWVudHMuanN4Jyk7XG52YXIgc3R5bGVzID0gcmVxdWlyZSgnLi9rb250b2QtcmVnaXN0ZXIuc3R5bGVzJyk7XG52YXIgRE9DX1RZUEVfSUQgPSAna29udG9kJztcblxuLyoqXHJcbiAqINCa0LvQsNGB0YEg0YDQtdCw0LvQuNC30YPQtdGCINC00L7QutGD0LzQtdC90YIg0YHQv9GA0LDQstC+0YfQvdC40LrQsCDQv9GA0LjQt9C90LDQutC+0LIuXHJcbiAqL1xuXG52YXIgS29udG9kID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKEtvbnRvZCwgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gS29udG9kKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBLb250b2QpO1xuXG4gICAgICAgIHJldHVybiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoS29udG9kLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoS29udG9kKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhLb250b2QsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudHMsIHsgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICByZWY6ICdyZWdpc3RlcicsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiBET0NfVFlQRV9JRCxcbiAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLFxuICAgICAgICAgICAgICAgIHJlbmRlcjogdGhpcy5yZW5kZXJlciB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBLb250b2Q7XG59KFJlYWN0LlB1cmVDb21wb25lbnQpO1xuXG5tb2R1bGUuZXhwb3J0cyA9IEtvbnRvZDtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3Mva29udG9kL2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMzg4XG4vLyBtb2R1bGUgY2h1bmtzID0gMSIsIid1c2Ugc3RyaWN0Jzttb2R1bGUuZXhwb3J0cz17Z3JpZDp7bWFpblRhYmxlOnt3aWR0aDonMTAwJScsdGQ6e2JvcmRlcjonMXB4IHNvbGlkIGxpZ2h0R3JleScsZGlzcGxheTondGFibGUtY2VsbCcscGFkZGluZ0xlZnQ6JzVweCd9fSxoZWFkZXJUYWJsZTp7d2lkdGg6JzEwMCUnfSxncmlkQ29udGFpbmVyOnt3aWR0aDonMTAwJSd9fX07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2tvbnRvZC9rb250b2QtcmVnaXN0ZXIuc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAzODlcbi8vIG1vZHVsZSBjaHVua3MgPSAxIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xuXG52YXIgRG9jdW1lbnRUZW1wbGF0ZSA9IHJlcXVpcmUoJy4vLi4vLi4vZG9jdW1lbnRUZW1wbGF0ZS9pbmRleC5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBJbnB1dERhdGUgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LWRhdGUvaW5wdXQtZGF0ZS5qc3gnKSxcbiAgICBTZWxlY3QgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL3NlbGVjdC9zZWxlY3QuanN4JyksXG4gICAgVGV4dEFyZWEgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL3RleHQtYXJlYS90ZXh0LWFyZWEuanN4JyksXG4gICAgc3R5bGVzID0gcmVxdWlyZSgnLi9rb250b2Qtc3R5bGVzJyk7XG5cbnZhciBLT05UT19UWVlQID0gW3sgaWQ6IDEsIGtvb2Q6IFwiU0RcIiwgbmFtZTogXCJTRFwiIH0sIHsgaWQ6IDIsIGtvb2Q6IFwiU0tcIiwgbmFtZTogXCJTS1wiIH0sIHsgaWQ6IDMsIGtvb2Q6IFwiRFwiLCBuYW1lOiBcIkRcIiB9LCB7IGlkOiA0LCBrb29kOiBcIktcIiwgbmFtZTogXCJLXCIgfV07XG5cbnZhciBLb250b2QgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoS29udG9kLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBLb250b2QocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIEtvbnRvZCk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKEtvbnRvZC5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKEtvbnRvZCkpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCksXG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZVxuICAgICAgICB9O1xuXG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoS29udG9kLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoRG9jdW1lbnRUZW1wbGF0ZSwgeyBkb2NJZDogdGhpcy5zdGF0ZS5kb2NJZCxcbiAgICAgICAgICAgICAgICByZWY6ICdkb2N1bWVudCcsXG4gICAgICAgICAgICAgICAgZG9jVHlwZUlkOiAnS09OVE9EJyxcbiAgICAgICAgICAgICAgICBoaXN0b3J5OiB0aGlzLnByb3BzLmhpc3RvcnkgPyB0aGlzLnByb3BzLmhpc3RvcnkgOiBudWxsLFxuICAgICAgICAgICAgICAgIGluaXREYXRhOiB0aGlzLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgIHJlbmRlcmVyOiB0aGlzLnJlbmRlcmVyLFxuICAgICAgICAgICAgICAgIGZvY3VzRWxlbWVudDogJ2lucHV0LWtvb2QnXG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuXG4gICAgICAgICAgICBpZiAoIXNlbGYuZG9jRGF0YSkge1xuICAgICAgICAgICAgICAgIHJldHVybiBudWxsO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdLb29kICcsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna29vZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1rb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmtvb2QgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdOaW1ldHVzICcsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbmltZXR1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1uaW1ldHVzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLm5pbWV0dXMgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChTZWxlY3QsIHsgdGl0bGU6ICdLb250byB0XFx4RkNcXHhGQ3AnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3R5eXAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogS09OVE9fVFlZUCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEudHl5cCB8fCAwLFxuICAgICAgICAgICAgICAgICAgICAgICAgZGVmYXVsdFZhbHVlOiBzZWxmLmRvY0RhdGEua29udG9fdHl5cCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3NlbGVjdC10eXlwJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIGJ0bkRlbGV0ZTogc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQgfSlcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXREYXRlLCB7IHRpdGxlOiAnS2VodGl2IGt1bmk6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICd2YWxpZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnZhbGlkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtdmFsaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFRleHRBcmVhLCB7IHRpdGxlOiAnTXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd0ZXh0YXJlYS1tdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5tdXVkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCB9KVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gS29udG9kO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuS29udG9kLnByb3BUeXBlcyA9IHtcbiAgICBkb2NJZDogUHJvcFR5cGVzLm51bWJlcixcbiAgICBpbml0RGF0YTogUHJvcFR5cGVzLm9iamVjdCxcbiAgICB1c2VyRGF0YTogUHJvcFR5cGVzLm9iamVjdFxufTtcblxuS29udG9kLmRlZmF1bHRQcm9wcyA9IHtcbiAgICBpbml0RGF0YToge30sXG4gICAgdXNlckRhdGE6IHt9XG59O1xubW9kdWxlLmV4cG9ydHMgPSBLb250b2Q7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2tvbnRvZC9kb2N1bWVudC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDM5MFxuLy8gbW9kdWxlIGNodW5rcyA9IDEiLCIndXNlIHN0cmljdCc7bW9kdWxlLmV4cG9ydHM9e2RvY1Jvdzp7ZGlzcGxheTonZmxleCcsZmxleERpcmVjdGlvbjoncm93Jy8qXHJcbiAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsdWUnXHJcbiovfSxkb2NDb2x1bW46e2Rpc3BsYXk6J2ZsZXgnLGZsZXhEaXJlY3Rpb246J2NvbHVtbicsLypcclxuICAgICAgICBib3JkZXI6ICcxcHggc29saWQgeWVsbG93JyxcclxuKi93aWR0aDonNTAlJ30sZG9jOntkaXNwbGF5OidmbGV4JyxmbGV4RGlyZWN0aW9uOidjb2x1bW4nLypcclxuICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYnJvd24nXHJcbiovfX07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2tvbnRvZC9kb2N1bWVudC9rb250b2Qtc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAzOTFcbi8vIG1vZHVsZSBjaHVua3MgPSAxIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgRG9jdW1lbnRzID0gcmVxdWlyZSgnLi8uLi9kb2N1bWVudHMvZG9jdW1lbnRzLmpzeCcpO1xudmFyIHN0eWxlcyA9IHJlcXVpcmUoJy4vcHJvamVjdC1yZWdpc3Rlci1zdHlsZXMnKTtcbnZhciBET0NfVFlQRV9JRCA9ICdwcm9qZWN0Jztcbi8qKlxyXG4gKiDQmtC70LDRgdGBINGA0LXQsNC70LjQt9GD0LXRgiDQtNC+0LrRg9C80LXQvdGCINGB0L/RgNCw0LLQvtGH0L3QuNC60LAg0L/RgNC40LfQvdCw0LrQvtCyLlxyXG4gKi9cblxudmFyIFByb2plY3QgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoUHJvamVjdCwgX1JlYWN0JFB1cmVDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gUHJvamVjdChwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgUHJvamVjdCk7XG5cbiAgICAgICAgcmV0dXJuIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChQcm9qZWN0Ll9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoUHJvamVjdCkpLmNhbGwodGhpcywgcHJvcHMpKTtcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoUHJvamVjdCwgW3tcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50cywgeyBpbml0RGF0YTogdGhpcy5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICB1c2VyRGF0YTogdGhpcy5wcm9wcy51c2VyRGF0YSxcbiAgICAgICAgICAgICAgICBoaXN0b3J5OiB0aGlzLnByb3BzLmhpc3RvcnkgPyB0aGlzLnByb3BzLmhpc3RvcnkgOiBudWxsLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBidG5FZGl0Q2xpY2s6IHRoaXMuYnRuRWRpdENsaWNrLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogRE9DX1RZUEVfSUQsXG4gICAgICAgICAgICAgICAgc3R5bGU6IHN0eWxlcyxcbiAgICAgICAgICAgICAgICByZW5kZXI6IHRoaXMucmVuZGVyZXIgfSk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcmVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcmVyKCkge1xuICAgICAgICAgICAgcmV0dXJuIG51bGw7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gUHJvamVjdDtcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbm1vZHVsZS5leHBvcnRzID0gUHJvamVjdDtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvcHJvamVjdC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDM5MlxuLy8gbW9kdWxlIGNodW5rcyA9IDEiLCIndXNlIHN0cmljdCc7bW9kdWxlLmV4cG9ydHM9e2dyaWQ6e21haW5UYWJsZTp7d2lkdGg6JzEwMCUnLHRkOntib3JkZXI6JzFweCBzb2xpZCBsaWdodEdyZXknLGRpc3BsYXk6J3RhYmxlLWNlbGwnLHBhZGRpbmdMZWZ0Oic1cHgnfX0saGVhZGVyVGFibGU6e3dpZHRoOicxMDAlJ30sZ3JpZENvbnRhaW5lcjp7d2lkdGg6JzEwMCUnfX19O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9wcm9qZWN0L3Byb2plY3QtcmVnaXN0ZXItc3R5bGVzLmpzXG4vLyBtb2R1bGUgaWQgPSAzOTNcbi8vIG1vZHVsZSBjaHVua3MgPSAxIiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xuXG52YXIgRG9jdW1lbnRUZW1wbGF0ZSA9IHJlcXVpcmUoJy4vLi4vLi4vZG9jdW1lbnRUZW1wbGF0ZS9pbmRleC5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBUZXh0QXJlYSA9IHJlcXVpcmUoJy4uLy4uLy4uL2NvbXBvbmVudHMvdGV4dC1hcmVhL3RleHQtYXJlYS5qc3gnKSxcbiAgICBzdHlsZXMgPSByZXF1aXJlKCcuL3Byb2plY3Qtc3R5bGVzJyk7XG5cbnZhciBQcm9qZWN0ID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKFByb2plY3QsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIFByb2plY3QocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIFByb2plY3QpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChQcm9qZWN0Ll9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoUHJvamVjdCkpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIGRvY0lkOiBwcm9wcy5kb2NJZCA/IHByb3BzLmRvY0lkIDogTnVtYmVyKHByb3BzLm1hdGNoLnBhcmFtcy5kb2NJZCksXG4gICAgICAgICAgICBsb2FkZWREYXRhOiBmYWxzZVxuICAgICAgICB9O1xuICAgICAgICBfdGhpcy5yZW5kZXJlciA9IF90aGlzLnJlbmRlcmVyLmJpbmQoX3RoaXMpO1xuXG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoUHJvamVjdCwgW3tcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50VGVtcGxhdGUsIHsgZG9jSWQ6IHRoaXMuc3RhdGUuZG9jSWQsXG4gICAgICAgICAgICAgICAgcmVmOiAnZG9jdW1lbnQnLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ1BST0pFQ1QnLFxuICAgICAgICAgICAgICAgIGhpc3Rvcnk6IHRoaXMucHJvcHMuaGlzdG9yeSxcbiAgICAgICAgICAgICAgICBpbml0RGF0YTogdGhpcy5wcm9wcy5pbml0RGF0YSxcbiAgICAgICAgICAgICAgICByZW5kZXJlcjogdGhpcy5yZW5kZXJlcixcbiAgICAgICAgICAgICAgICBmb2N1c0VsZW1lbnQ6ICdpbnB1dC1rb29kJ1xuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQnNC10YLQvtC0INCy0LXRgNC90LXRgiDQutCw0YHRgtC+0LzQvdGL0Lkg0LrQvtC80L/QvtC90LXQvdGCXHJcbiAgICAgICAgICogQHBhcmFtIHNlbGZcclxuICAgICAgICAgKiBAcmV0dXJucyB7Kn1cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoc2VsZikge1xuICAgICAgICAgICAgaWYgKCFzZWxmLmRvY0RhdGEpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2MgfSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ0tvb2QgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LWtvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEua29vZCxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ05pbWV0dXMgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICduaW1ldHVzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LW5pbWV0dXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubmltZXR1cyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFRleHRBcmVhLCB7IHRpdGxlOiAnTXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd0ZXh0YXJlYS1tdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5tdXVkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCB9KVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICB9XSk7XG5cbiAgICByZXR1cm4gUHJvamVjdDtcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cblByb2plY3QucHJvcFR5cGVzID0ge1xuICAgIGRvY0lkOiBQcm9wVHlwZXMubnVtYmVyLFxuICAgIGluaXREYXRhOiBQcm9wVHlwZXMub2JqZWN0LFxuICAgIHVzZXJEYXRhOiBQcm9wVHlwZXMub2JqZWN0XG59O1xuXG5Qcm9qZWN0LmRlZmF1bHRQcm9wcyA9IHtcbiAgICBpbml0RGF0YToge30sXG4gICAgdXNlckRhdGE6IHt9XG59O1xubW9kdWxlLmV4cG9ydHMgPSBQcm9qZWN0O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9wcm9qZWN0L2RvY3VtZW50L2luZGV4LmpzeFxuLy8gbW9kdWxlIGlkID0gMzk0XG4vLyBtb2R1bGUgY2h1bmtzID0gMSIsIid1c2Ugc3RyaWN0Jzttb2R1bGUuZXhwb3J0cz17ZG9jUm93OntkaXNwbGF5OidmbGV4JyxmbGV4RGlyZWN0aW9uOidyb3cnLypcclxuICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYmx1ZSdcclxuKi99LGRvY0NvbHVtbjp7ZGlzcGxheTonZmxleCcsZmxleERpcmVjdGlvbjonY29sdW1uJywvKlxyXG4gICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCB5ZWxsb3cnLFxyXG4qL3dpZHRoOic1MCUnfSxkb2M6e2Rpc3BsYXk6J2ZsZXgnLGZsZXhEaXJlY3Rpb246J2NvbHVtbicvKlxyXG4gICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBicm93bidcclxuKi99fTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvcHJvamVjdC9kb2N1bWVudC9wcm9qZWN0LXN0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMzk1XG4vLyBtb2R1bGUgY2h1bmtzID0gMSIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIERvY3VtZW50cyA9IHJlcXVpcmUoJy4vLi4vZG9jdW1lbnRzL2RvY3VtZW50cy5qc3gnKTtcbnZhciBzdHlsZXMgPSByZXF1aXJlKCcuL2RvY3MtcmVnaXN0ZXItc3R5bGVzJyk7XG5cbi8qKlxyXG4gKiDQmtC70LDRgdGBINGA0LXQsNC70LjQt9GD0LXRgiDRgdC/0YDQsNCy0L7Rh9C90LjQuiDQtNC+0LrRg9C80LXQvdGC0L7QsiDQv9C+0LvRjNC30L7QstCw0YLQtdC70Y8uXHJcbiAqL1xuXG52YXIgRG9jcyA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhEb2NzLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBEb2NzKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBEb2NzKTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoRG9jcy5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKERvY3MpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMuZ3JpZERhdGEgPSBwcm9wcy5pbml0RGF0YS5yZXN1bHQuZGF0YTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhEb2NzLCBbe1xuICAgICAgICBrZXk6ICdyZW5kZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyKCkge1xuICAgICAgICAgICAgdmFyIGRvY1R5cGVJZCA9IHRoaXMucHJvcHMuaW5pdERhdGEuZG9jVHlwZUlkO1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudHMsIHsgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgaGlzdG9yeTogdGhpcy5wcm9wcy5oaXN0b3J5ID8gdGhpcy5wcm9wcy5oaXN0b3J5IDogbnVsbCxcbiAgICAgICAgICAgICAgICBtb2R1bGU6IHRoaXMucHJvcHMubW9kdWxlLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogZG9jVHlwZUlkLFxuICAgICAgICAgICAgICAgIHJlZjogJ3JlZ2lzdGVyJyxcbiAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLFxuICAgICAgICAgICAgICAgIHJlbmRlcjogdGhpcy5yZW5kZXJlciB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcmVuZGVyZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBEb2NzO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxubW9kdWxlLmV4cG9ydHMgPSBEb2NzO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9kb2svaW5kZXguanN4XG4vLyBtb2R1bGUgaWQgPSAzOTZcbi8vIG1vZHVsZSBjaHVua3MgPSAxIiwiJ3VzZSBzdHJpY3QnO21vZHVsZS5leHBvcnRzPXtncmlkOnttYWluVGFibGU6e3dpZHRoOicxMDAlJ30saGVhZGVyVGFibGU6e3dpZHRoOicxMDAlJ30sZ3JpZENvbnRhaW5lcjp7d2lkdGg6JzEwMCUnfX19O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9kb2svZG9jcy1yZWdpc3Rlci1zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDM5N1xuLy8gbW9kdWxlIGNodW5rcyA9IDEiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFByb3BUeXBlcyA9IHJlcXVpcmUoJ3Byb3AtdHlwZXMnKTtcbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG5cbnZhciBEb2N1bWVudFRlbXBsYXRlID0gcmVxdWlyZSgnLi4vLi4vZG9jdW1lbnRUZW1wbGF0ZS9pbmRleC5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBTZWxlY3QgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL3NlbGVjdC9zZWxlY3QuanN4JyksXG4gICAgVGV4dEFyZWEgPSByZXF1aXJlKCcuLi8uLi8uLi9jb21wb25lbnRzL3RleHQtYXJlYS90ZXh0LWFyZWEuanN4JyksXG4gICAgc3R5bGVzID0gcmVxdWlyZSgnLi9kb2N1bWVudC1zdHlsZXMnKSxcbiAgICBET0NVTUVOVF9UWVBFUyA9IFt7IGlkOiAxLCBrb29kOiAnZG9jdW1lbnQnLCBuYW1lOiAnZG9jdW1lbnQnIH0sIHsgaWQ6IDIsIGtvb2Q6ICdsaWJyYXJ5JywgbmFtZTogJ2xpYnJhcnknIH1dO1xuXG4vKipcclxuICog0KDQtdCw0LvQuNC30YPQtdGCINC00L7QutGD0LzQtdC90YIg0YHQv9GA0LDQstC+0YfQvdC40LrQsCDQotC40L/RiyDQtNC+0LrRg9C80LXQvdGC0L7QslxyXG4gKi9cblxudmFyIERvY3VtZW50ID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKERvY3VtZW50LCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBEb2N1bWVudChwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgRG9jdW1lbnQpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChEb2N1bWVudC5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKERvY3VtZW50KSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgZG9jSWQ6IHByb3BzLmRvY0lkID8gcHJvcHMuZG9jSWQgOiBOdW1iZXIocHJvcHMubWF0Y2gucGFyYW1zLmRvY0lkKSxcbiAgICAgICAgICAgIGxvYWRlZERhdGE6IGZhbHNlXG4gICAgICAgIH07XG4gICAgICAgIF90aGlzLnJlbmRlcmVyID0gX3RoaXMucmVuZGVyZXIuYmluZChfdGhpcyk7XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoRG9jdW1lbnQsIFt7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChEb2N1bWVudFRlbXBsYXRlLCB7IGRvY0lkOiB0aGlzLnN0YXRlLmRvY0lkLFxuICAgICAgICAgICAgICAgIHJlZjogJ2RvY3VtZW50JyxcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQ6ICdET0snLFxuICAgICAgICAgICAgICAgIGluaXREYXRhOiB0aGlzLnByb3BzLmluaXREYXRhLFxuICAgICAgICAgICAgICAgIHJlbmRlcmVyOiB0aGlzLnJlbmRlcmVyIH0pO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcihzZWxmKSB7XG4gICAgICAgICAgICBpZiAoIXNlbGYuZG9jRGF0YSkge1xuICAgICAgICAgICAgICAgIHJldHVybiBudWxsO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jIH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnS29vZCAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1rb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmtvb2QsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ05pbWV0dXMgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbmltZXR1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtbmltZXR1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS5uaW1ldHVzLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSlcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChTZWxlY3QsIHsgdGl0bGU6ICdUXFx4RkNcXHhGQ3A6JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAndHlwZScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogRE9DVU1FTlRfVFlQRVMsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sbElkOiAna29vZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHNlbGYuZG9jRGF0YS50eXBlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlZmF1bHRWYWx1ZTogc2VsZi5kb2NEYXRhLnR5cGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LXR5cGUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJ0bkRlbGV0ZTogIXNlbGYuc3RhdGUuZWRpdGVkLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhc2VsZi5zdGF0ZS5lZGl0ZWQgfSlcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChUZXh0QXJlYSwgeyB0aXRsZTogJ011dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdtdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICd0ZXh0YXJlYS1tdXVkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLm11dWQgfHwgJycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFzZWxmLnN0YXRlLmVkaXRlZCB9KVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBEb2N1bWVudDtcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG5cbkRvY3VtZW50LnByb3BUeXBlcyA9IHtcbiAgICBkb2NJZDogUHJvcFR5cGVzLm51bWJlcixcbiAgICBpbml0RGF0YTogUHJvcFR5cGVzLm9iamVjdCxcbiAgICB1c2VyRGF0YTogUHJvcFR5cGVzLm9iamVjdFxufTtcblxuRG9jdW1lbnQuZGVmYXVsdFByb3BzID0ge1xuICAgIGluaXREYXRhOiB7fSxcbiAgICB1c2VyRGF0YToge31cbn07XG5cbm1vZHVsZS5leHBvcnRzID0gRG9jdW1lbnQ7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2Rvay9kb2N1bWVudC9pbmRleC5qc3hcbi8vIG1vZHVsZSBpZCA9IDM5OFxuLy8gbW9kdWxlIGNodW5rcyA9IDEiLCIndXNlIHN0cmljdCc7bW9kdWxlLmV4cG9ydHM9e2RvY1Jvdzp7ZGlzcGxheTonZmxleCcsZmxleERpcmVjdGlvbjoncm93Jy8qXHJcbiAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJsdWUnXHJcbiovfSxkb2NDb2x1bW46e2Rpc3BsYXk6J2ZsZXgnLGZsZXhEaXJlY3Rpb246J2NvbHVtbicsLypcclxuICAgICAgICBib3JkZXI6ICcxcHggc29saWQgeWVsbG93JyxcclxuKi93aWR0aDonNTAlJ30sZG9jOntkaXNwbGF5OidmbGV4JyxmbGV4RGlyZWN0aW9uOidjb2x1bW4nLypcclxuICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYnJvd24nXHJcbiovfX07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2Rvay9kb2N1bWVudC9kb2N1bWVudC1zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDM5OVxuLy8gbW9kdWxlIGNodW5rcyA9IDEiXSwibWFwcGluZ3MiOiI7Ozs7OztBQUFBOzs7Ozs7O0FDQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUN2TEE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDL0NBOzs7Ozs7O0FDQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNoREE7Ozs7Ozs7QUNBQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2phQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzFGQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDM0lBOzs7Ozs7O0FDQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNOQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2hEQTs7Ozs7OztBQ0FBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDcElBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDTkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2pEQTs7Ozs7OztBQ0FBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzlHQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ05BO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ3JEQTs7Ozs7OztBQ0FBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzdIQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7OzsiLCJzb3VyY2VSb290IjoiIn0=