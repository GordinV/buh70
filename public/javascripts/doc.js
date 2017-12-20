var doc =
webpackJsonp_name_([4],{

/***/ 0:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var ReactDOM = __webpack_require__(1);

	// данные для хранилища
	localStorage['docStore'] = storeData;
	storeData = JSON.parse(storeData);
	userData = JSON.parse(userData);

	// создаем обработчик события на изменение даннх


	// запросим компонент документа по его типу
	var Doc = __webpack_require__(172)(storeData.docTypeId);

	ReactDOM.hydrate(React.createElement(Doc, { data: storeData.data, bpm: storeData.bpm, userData: userData }), document.getElementById('doc'));

/***/ }),

/***/ 2:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(3);

	var React = __webpack_require__(13);

	var DocumentTemplate = __webpack_require__(14),
	    InputText = __webpack_require__(75),
	    InputDate = __webpack_require__(77),
	    InputNumber = __webpack_require__(79),
	    DocCommon = __webpack_require__(81),
	    Select = __webpack_require__(84),
	    TextArea = __webpack_require__(86),
	    DataGrid = __webpack_require__(88),
	    DokProp = __webpack_require__(156),
	    relatedDocuments = __webpack_require__(157),
	    ModalPage = __webpack_require__(158),
	    styles = __webpack_require__(160);

	var LIBDOK = 'ARV',
	    LIBRARIES = ['asutused', 'kontod', 'dokProps', 'users', 'aa', 'tunnus', 'project', 'nomenclature'];

	var now = new Date();

	var Arve = function (_React$PureComponent) {
	    _inherits(Arve, _React$PureComponent);

	    function Arve(props) {
	        _classCallCheck(this, Arve);

	        var _this = _possibleConstructorReturn(this, (Arve.__proto__ || Object.getPrototypeOf(Arve)).call(this, props));

	        _this.state = {
	            loadedData: false
	        };

	        _this.createGridRow = _this.createGridRow.bind(_this);
	        _this.recalcDocSumma = _this.recalcDocSumma.bind(_this);

	        _this.renderer = _this.renderer.bind(_this);
	        _this.gridValidateFields = _this.gridValidateFields.bind(_this);

	        _this.pages = [{ pageName: 'Arve' }];
	        _this.requiredFields = [{
	            name: 'kpv',
	            type: 'D',
	            min: now.setFullYear(now.getFullYear() - 1),
	            max: now.setFullYear(now.getFullYear() + 1)
	        }, {
	            name: 'tahtaeg',
	            type: 'D',
	            min: now.setFullYear(now.getFullYear() - 1),
	            max: now.setFullYear(now.getFullYear() + 1)
	        }, { name: 'asutusid', type: 'N', min: null, max: null }, { name: 'summa', type: 'N', min: -9999999, max: 999999 }];

	        return _this;
	    }

	    _createClass(Arve, [{
	        key: 'render',
	        value: function render() {
	            return React.createElement(DocumentTemplate, { docId: this.props.docId,
	                ref: 'document',
	                docTypeId: 'ARV',
	                requiredFields: this.requiredFields,
	                userData: this.props.userData,
	                initData: this.props.initData,
	                libs: LIBRARIES,
	                pages: this.pages,
	                renderer: this.renderer,
	                createGridRow: this.createGridRow,
	                gridValidator: this.gridValidateFields,
	                recalcDoc: this.recalcDocSumma
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
	                gridData = self.docData.gridData,
	                gridColumns = self.docData.gridConfig;

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
	                        React.createElement(DocCommon, {
	                            ref: 'doc-common',
	                            data: self.docData,
	                            readOnly: !isEditMode })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(
	                            'div',
	                            { style: styles.docColumn },
	                            React.createElement(InputText, { ref: 'input-number',
	                                title: 'Number',
	                                name: 'number',
	                                value: self.docData.number || '',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange }),
	                            React.createElement(InputDate, { title: 'Kuup\xE4ev ',
	                                name: 'kpv', value: self.docData.kpv,
	                                ref: 'input-kpv',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange }),
	                            React.createElement(InputDate, { title: 'T\xE4htaeg ',
	                                name: 'tahtaeg',
	                                value: self.docData.tahtaeg,
	                                ref: 'input-tahtaeg',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange }),
	                            React.createElement(Select, { title: 'Asutus',
	                                name: 'asutusid',
	                                libs: 'asutused',
	                                data: self.libs['asutused'],
	                                value: self.docData.asutusid || 0,
	                                defaultValue: self.docData.asutus,
	                                ref: 'select-asutusid',
	                                btnDelete: isEditMode,
	                                onChange: self.handleInputChange,
	                                readOnly: !isEditMode }),
	                            React.createElement(InputText, { title: 'Lisa ',
	                                name: 'lisa',
	                                value: self.docData.lisa || '',
	                                ref: 'input-lisa',
	                                readOnly: !isEditMode,
	                                onChange: self.handleInputChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docColumn },
	                            React.createElement(DokProp, { title: 'Konteerimine: ',
	                                name: 'doklausid',
	                                libs: 'dokProps',
	                                value: self.docData.doklausid,
	                                defaultValue: self.docData.dokprop,
	                                ref: 'dokprop-doklausid',
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
	                        React.createElement(DataGrid, { source: 'details',
	                            gridData: gridData,
	                            gridColumns: gridColumns,
	                            showToolBar: isEditMode,
	                            handleGridRow: this.handleGridRow,
	                            handleGridBtnClick: self.handleGridBtnClick,
	                            readOnly: !isEditMode,
	                            style: styles.grid.headerTable,
	                            ref: 'data-grid' })
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.docRow },
	                        React.createElement(InputNumber, { title: 'Summa ',
	                            name: 'summa',
	                            ref: 'input-summa',
	                            value: Number(self.docData.summa) || 0,
	                            disabled: true,
	                            width: 'auto',
	                            onChange: self.handleInputChange }),
	                        React.createElement(InputNumber, { title: 'K\xE4ibemaks ',
	                            name: 'kbm',
	                            ref: 'input-kbm',
	                            disabled: true,
	                            width: 'auto',
	                            value: Number(self.docData.kbm) || 0,
	                            onChange: self.handleInputChange
	                        })
	                    ),
	                    self.state.gridRowEdit ? this.createGridRow(self) : null
	                )
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
	                                data: nomData,
	                                readOnly: false,
	                                value: row.nomid,
	                                collId: 'id',
	                                ref: 'nomid',
	                                placeholder: 'Teenuse kood',
	                                onChange: self.handleGridRowChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Kogus ',
	                                name: 'kogus',
	                                value: Number(row.kogus),
	                                readOnly: false,
	                                disabled: false,
	                                bindData: false,
	                                ref: 'kogus',
	                                onChange: self.handleGridRowInput })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Hind ',
	                                name: 'hind',
	                                value: Number(row.hind),
	                                readOnly: false,
	                                disabled: false,
	                                bindData: false,
	                                ref: 'hind',
	                                onChange: self.handleGridRowInput })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Kbm-ta: ',
	                                name: 'kbmta',
	                                value: Number(row.kbmta),
	                                disabled: true,
	                                bindData: false,
	                                ref: 'kbmta',
	                                onChange: self.handleGridRowChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Kbm: ',
	                                name: 'kbm',
	                                value: Number(row.kbm),
	                                disabled: true,
	                                bindData: false,
	                                ref: 'kbm',
	                                onBlur: self.handleGridRowInput })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Summa: ',
	                                name: 'Summa',
	                                value: Number(row.summa),
	                                disabled: true,
	                                bindData: false,
	                                ref: 'summa',
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
	                if (!doc.gridRowData['kogus']) warning = warning + ' Количество';
	                if (!doc.gridRowData['summa']) warning = warning + ' Сумма';

	                this.recalcRowSumm();
	                this.recalcDocSumma('summa');
	            }
	            return warning;
	        }

	        /**
	         * перерасчет суммы строки и расчет налога
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

	            var vat = nomDataName[0].vat ? Number(nomDataName[0].vat) / 100 : 0;
	            if (doc.gridRowData['nomid']) {
	                doc.gridRowData['kood'] = nomDataName[0].kood;
	                doc.gridRowData['nimetus'] = nomDataName[0].name;
	            }

	            doc.gridRowData['kogus'] = Number(doc.gridRowData.kogus);
	            doc.gridRowData['hind'] = Number(doc.gridRowData.hind);
	            doc.gridRowData['kbmta'] = Number(doc.gridRowData['kogus']) * Number(doc.gridRowData['hind']);
	            doc.gridRowData['kbm'] = Number(doc.gridRowData['kbmta']) * vat;
	            doc.gridRowData['summa'] = Number(doc.gridRowData['kbmta']) + Number(doc.gridRowData['kbm']);
	        }

	        /**
	         * Перерасчет итоговых сумм документа
	         */

	    }, {
	        key: 'recalcDocSumma',
	        value: function recalcDocSumma() {
	            var doc = this.refs['document'];

	            doc.docData['summa'] = 0;
	            doc.docData['kbm'] = 0;
	            doc.docData.gridData.forEach(function (row) {
	                doc.docData['summa'] += Number(row['summa']);
	                doc.docData['kbm'] += Number(row['kbm']);
	            });
	        }
	    }]);

	    return Arve;
	}(React.PureComponent);

	Arve.propTypes = {
	    docId: PropTypes.number.isRequired,
	    initData: PropTypes.object,
	    userData: PropTypes.object
	};

	module.exports = Arve;

/***/ }),

/***/ 160:
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
	    summa: {
	        width: 'auto'
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

/***/ 172:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	module.exports = function (docTypeId) {
	    // взависимости от типа документа вернет компонент документа

	    console.log('returnDocComponent:' + docTypeId);
	    var component = {};

	    switch (docTypeId) {
	        case 'PALK':
	            component = __webpack_require__(173);
	            break;
	        default:
	            component = __webpack_require__(2);
	    }
	    return component;
	};

/***/ }),

/***/ 173:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var React = __webpack_require__(13);
	var Form = __webpack_require__(174);
	var PageLabel = __webpack_require__(175);

	var pages = ['Page1', 'Page2'];

	var Palk = React.createClass({
	    displayName: 'Palk',

	    render: function render() {
	        return React.createElement(
	            Form,
	            { pages: pages },
	            React.createElement(
	                'span',
	                null,
	                ' Palk '
	            )
	        );
	    } });

	module.exports = Palk;

/***/ }),

/***/ 174:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var React = __webpack_require__(13),
	    flux = __webpack_require__(43);

	var PageLabel = __webpack_require__(175);

	var Form = React.createClass({
	    displayName: 'Form',

	    getInitialState: function getInitialState() {
	        var pages = [{ pageName: 'Page' }];
	        if (this.props.pages) {
	            pages = this.props.pages;
	        }
	        return {
	            pages: this.props.pages
	        };
	    },

	    render: function render() {
	        var pages = this.state.pages;
	        return React.createElement('div', { className: 'container' }, pages.map(function (page, idx) {
	            return React.createElement(PageLabel, { key: idx, pageIdx: idx }, page);
	        }), React.createElement('div', { className: 'page' }, React.createElement('form', null, this.props.children)));
	    }
	});

	module.exports = Form;

/***/ }),

/***/ 175:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var React = __webpack_require__(13),
	    flux = __webpack_require__(43);

	var PageLabel = React.createClass({
	    displayName: 'PageLabel',
	    getInitialState: function getInitialState() {
	        return {
	            disabled: false
	        };
	    },

	    componentDidMount: function componentDidMount() {
	        var self = this;
	        //      console.log('page label componentWillMount')
	        flux.stores.docStore.on('change:edited', function (newValue, previousValue) {
	            self.setState({ disabled: newValue });
	        });
	    },

	    handleClick: function handleClick(page) {
	        // обработчик на событие клик, подгружаем связанный документ
	        //       alert('click:' + pageName);
	        // docTypeId: doc.doc_type, docId:doc.id, pageName:'Lausend id:' + doc.id

	        if (this.state.disabled) {
	            console.log('page disabled');
	            return;
	        }

	        if (page.docId) {
	            console.log('handleClick page.docTypeId %s, page.docId %n');
	            var url = "/document/" + page.docTypeId + page.docId;
	            document.location.href = url;
	        }
	    },

	    render: function render() {
	        var className = 'pageLabel';

	        return React.createElement('label', { className: className, onClick: this.handleClick.bind(this, this.props.children), disabled: this.state.disabled }, this.props.children.pageName, ' ');
	    }
	});

	module.exports = PageLabel;

/***/ })

});
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZG9jLmpzIiwic291cmNlcyI6WyJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvYXJ2L2Fydi5qc3g/MTY5YyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2Fydi9hcnZlLnN0eWxlcy5qcz9hZjVmIiwid2VicGFjazovLy8uL21pZGRsZXdhcmUvcmV0dXJuRG9jQ29tcG9uZW50LmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvcGFsa19vcGVyLmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9jb21wb25lbnRzL2Zvcm0uanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvY29tcG9uZW50cy9wYWdlX2xhYmVsLmpzIl0sInNvdXJjZXNDb250ZW50IjpbIid1c2Ugc3RyaWN0JztcblxudmFyIFJlYWN0RE9NID0gcmVxdWlyZSgncmVhY3QtZG9tJyk7XG5cbi8vINC00LDQvdC90YvQtSDQtNC70Y8g0YXRgNCw0L3QuNC70LjRidCwXG5sb2NhbFN0b3JhZ2VbJ2RvY1N0b3JlJ10gPSBzdG9yZURhdGE7XG5zdG9yZURhdGEgPSBKU09OLnBhcnNlKHN0b3JlRGF0YSk7XG51c2VyRGF0YSA9IEpTT04ucGFyc2UodXNlckRhdGEpO1xuXG4vLyDRgdC+0LfQtNCw0LXQvCDQvtCx0YDQsNCx0L7RgtGH0LjQuiDRgdC+0LHRi9GC0LjRjyDQvdCwINC40LfQvNC10L3QtdC90LjQtSDQtNCw0L3QvdGFXG5cblxuLy8g0LfQsNC/0YDQvtGB0LjQvCDQutC+0LzQv9C+0L3QtdC90YIg0LTQvtC60YPQvNC10L3RgtCwINC/0L4g0LXQs9C+INGC0LjQv9GDXG52YXIgRG9jID0gcmVxdWlyZSgnLi4vbWlkZGxld2FyZS9yZXR1cm5Eb2NDb21wb25lbnQnKShzdG9yZURhdGEuZG9jVHlwZUlkKTtcblxuUmVhY3RET00uaHlkcmF0ZShSZWFjdC5jcmVhdGVFbGVtZW50KERvYywgeyBkYXRhOiBzdG9yZURhdGEuZGF0YSwgYnBtOiBzdG9yZURhdGEuYnBtLCB1c2VyRGF0YTogdXNlckRhdGEgfSksIGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCdkb2MnKSk7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2MuanNcbi8vIG1vZHVsZSBpZCA9IDBcbi8vIG1vZHVsZSBjaHVua3MgPSA0IiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBQcm9wVHlwZXMgPSByZXF1aXJlKCdwcm9wLXR5cGVzJyk7XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0Jyk7XG5cbnZhciBEb2N1bWVudFRlbXBsYXRlID0gcmVxdWlyZSgnLi4vZG9jdW1lbnRUZW1wbGF0ZS9pbmRleC5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBJbnB1dERhdGUgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2lucHV0LWRhdGUvaW5wdXQtZGF0ZS5qc3gnKSxcbiAgICBJbnB1dE51bWJlciA9IHJlcXVpcmUoJy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtbnVtYmVyL2lucHV0LW51bWJlci5qc3gnKSxcbiAgICBEb2NDb21tb24gPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2RvYy1jb21tb24vZG9jLWNvbW1vbi5qc3gnKSxcbiAgICBTZWxlY3QgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL3NlbGVjdC9zZWxlY3QuanN4JyksXG4gICAgVGV4dEFyZWEgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL3RleHQtYXJlYS90ZXh0LWFyZWEuanN4JyksXG4gICAgRGF0YUdyaWQgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2RhdGEtZ3JpZC9kYXRhLWdyaWQuanN4JyksXG4gICAgRG9rUHJvcCA9IHJlcXVpcmUoJy4uLy4uL2NvbXBvbmVudHMvZG9jcHJvcC9kb2Nwcm9wLmpzeCcpLFxuICAgIHJlbGF0ZWREb2N1bWVudHMgPSByZXF1aXJlKCcuLi8uLi9taXhpbi9yZWxhdGVkRG9jdW1lbnRzLmpzeCcpLFxuICAgIE1vZGFsUGFnZSA9IHJlcXVpcmUoJy4uLy4uL2NvbXBvbmVudHMvbW9kYWxwYWdlL21vZGFsUGFnZS5qc3gnKSxcbiAgICBzdHlsZXMgPSByZXF1aXJlKCcuL2FydmUuc3R5bGVzJyk7XG5cbnZhciBMSUJET0sgPSAnQVJWJyxcbiAgICBMSUJSQVJJRVMgPSBbJ2FzdXR1c2VkJywgJ2tvbnRvZCcsICdkb2tQcm9wcycsICd1c2VycycsICdhYScsICd0dW5udXMnLCAncHJvamVjdCcsICdub21lbmNsYXR1cmUnXTtcblxudmFyIG5vdyA9IG5ldyBEYXRlKCk7XG5cbnZhciBBcnZlID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKEFydmUsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIEFydmUocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIEFydmUpO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChBcnZlLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoQXJ2ZSkpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIGxvYWRlZERhdGE6IGZhbHNlXG4gICAgICAgIH07XG5cbiAgICAgICAgX3RoaXMuY3JlYXRlR3JpZFJvdyA9IF90aGlzLmNyZWF0ZUdyaWRSb3cuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLnJlY2FsY0RvY1N1bW1hID0gX3RoaXMucmVjYWxjRG9jU3VtbWEuYmluZChfdGhpcyk7XG5cbiAgICAgICAgX3RoaXMucmVuZGVyZXIgPSBfdGhpcy5yZW5kZXJlci5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuZ3JpZFZhbGlkYXRlRmllbGRzID0gX3RoaXMuZ3JpZFZhbGlkYXRlRmllbGRzLmJpbmQoX3RoaXMpO1xuXG4gICAgICAgIF90aGlzLnBhZ2VzID0gW3sgcGFnZU5hbWU6ICdBcnZlJyB9XTtcbiAgICAgICAgX3RoaXMucmVxdWlyZWRGaWVsZHMgPSBbe1xuICAgICAgICAgICAgbmFtZTogJ2twdicsXG4gICAgICAgICAgICB0eXBlOiAnRCcsXG4gICAgICAgICAgICBtaW46IG5vdy5zZXRGdWxsWWVhcihub3cuZ2V0RnVsbFllYXIoKSAtIDEpLFxuICAgICAgICAgICAgbWF4OiBub3cuc2V0RnVsbFllYXIobm93LmdldEZ1bGxZZWFyKCkgKyAxKVxuICAgICAgICB9LCB7XG4gICAgICAgICAgICBuYW1lOiAndGFodGFlZycsXG4gICAgICAgICAgICB0eXBlOiAnRCcsXG4gICAgICAgICAgICBtaW46IG5vdy5zZXRGdWxsWWVhcihub3cuZ2V0RnVsbFllYXIoKSAtIDEpLFxuICAgICAgICAgICAgbWF4OiBub3cuc2V0RnVsbFllYXIobm93LmdldEZ1bGxZZWFyKCkgKyAxKVxuICAgICAgICB9LCB7IG5hbWU6ICdhc3V0dXNpZCcsIHR5cGU6ICdOJywgbWluOiBudWxsLCBtYXg6IG51bGwgfSwgeyBuYW1lOiAnc3VtbWEnLCB0eXBlOiAnTicsIG1pbjogLTk5OTk5OTksIG1heDogOTk5OTk5IH1dO1xuXG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoQXJ2ZSwgW3tcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KERvY3VtZW50VGVtcGxhdGUsIHsgZG9jSWQ6IHRoaXMucHJvcHMuZG9jSWQsXG4gICAgICAgICAgICAgICAgcmVmOiAnZG9jdW1lbnQnLFxuICAgICAgICAgICAgICAgIGRvY1R5cGVJZDogJ0FSVicsXG4gICAgICAgICAgICAgICAgcmVxdWlyZWRGaWVsZHM6IHRoaXMucmVxdWlyZWRGaWVsZHMsXG4gICAgICAgICAgICAgICAgdXNlckRhdGE6IHRoaXMucHJvcHMudXNlckRhdGEsXG4gICAgICAgICAgICAgICAgaW5pdERhdGE6IHRoaXMucHJvcHMuaW5pdERhdGEsXG4gICAgICAgICAgICAgICAgbGliczogTElCUkFSSUVTLFxuICAgICAgICAgICAgICAgIHBhZ2VzOiB0aGlzLnBhZ2VzLFxuICAgICAgICAgICAgICAgIHJlbmRlcmVyOiB0aGlzLnJlbmRlcmVyLFxuICAgICAgICAgICAgICAgIGNyZWF0ZUdyaWRSb3c6IHRoaXMuY3JlYXRlR3JpZFJvdyxcbiAgICAgICAgICAgICAgICBncmlkVmFsaWRhdG9yOiB0aGlzLmdyaWRWYWxpZGF0ZUZpZWxkcyxcbiAgICAgICAgICAgICAgICByZWNhbGNEb2M6IHRoaXMucmVjYWxjRG9jU3VtbWFcbiAgICAgICAgICAgIH0pO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICrQktC10YDQvdC10YIg0LrQsNGB0YLQvtC80L3Ri9C1INC60L7QvNC/0L7QvdC10L3RgtGLINC00L7QutGD0LzQtdC90YLQsFxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJlcihzZWxmKSB7XG4gICAgICAgICAgICB2YXIgYnBtID0gc2VsZi5kb2NEYXRhICYmIHNlbGYuZG9jRGF0YS5icG0gPyBzZWxmLmRvY0RhdGEuYnBtIDogW10sXG4gICAgICAgICAgICAgICAgaXNFZGl0TW9kZSA9IHNlbGYuc3RhdGUuZWRpdGVkLFxuICAgICAgICAgICAgICAgIGdyaWREYXRhID0gc2VsZi5kb2NEYXRhLmdyaWREYXRhLFxuICAgICAgICAgICAgICAgIGdyaWRDb2x1bW5zID0gc2VsZi5kb2NEYXRhLmdyaWRDb25maWc7XG5cbiAgICAgICAgICAgIC8vINGE0L7RgNC80LjRgNGD0LXQvCDQt9Cw0LLQuNGB0LjQvNC+0YHRgtC4XG4gICAgICAgICAgICBpZiAoc2VsZi5kb2NEYXRhLnJlbGF0aW9ucykge1xuICAgICAgICAgICAgICAgIHJlbGF0ZWREb2N1bWVudHMoc2VsZik7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHZhciBkb2MgPSB0aGlzLnJlZnNbJ2RvY3VtZW50J107XG4gICAgICAgICAgICB2YXIgbGlicyA9IGRvYyA/IGRvYy5saWJzIDoge307XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2MgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEb2NDb21tb24sIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdkb2MtY29tbW9uJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBzZWxmLmRvY0RhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY0NvbHVtbiB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHJlZjogJ2lucHV0LW51bWJlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpdGxlOiAnTnVtYmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ251bWJlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubnVtYmVyIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXREYXRlLCB7IHRpdGxlOiAnS3V1cFxceEU0ZXYgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2twdicsIHZhbHVlOiBzZWxmLmRvY0RhdGEua3B2LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1rcHYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXREYXRlLCB7IHRpdGxlOiAnVFxceEU0aHRhZWcgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ3RhaHRhZWcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLnRhaHRhZWcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXRhaHRhZWcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnQXN1dHVzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2FzdXR1c2lkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbGliczogJ2FzdXR1c2VkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YTogc2VsZi5saWJzWydhc3V0dXNlZCddLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmFzdXR1c2lkIHx8IDAsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlZmF1bHRWYWx1ZTogc2VsZi5kb2NEYXRhLmFzdXR1cyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnc2VsZWN0LWFzdXR1c2lkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYnRuRGVsZXRlOiBpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnTGlzYSAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbGlzYScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubGlzYSB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtbGlzYScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlSW5wdXRDaGFuZ2UgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KERva1Byb3AsIHsgdGl0bGU6ICdLb250ZWVyaW1pbmU6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdkb2tsYXVzaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBsaWJzOiAnZG9rUHJvcHMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogc2VsZi5kb2NEYXRhLmRva2xhdXNpZCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVmYXVsdFZhbHVlOiBzZWxmLmRvY0RhdGEuZG9rcHJvcCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnZG9rcHJvcC1kb2tsYXVzaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChUZXh0QXJlYSwgeyB0aXRsZTogJ01cXHhFNHJrdXNlZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ211dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3RleHRhcmVhLW11dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBzZWxmLmRvY0RhdGEubXV1ZCB8fCAnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUgfSlcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEYXRhR3JpZCwgeyBzb3VyY2U6ICdkZXRhaWxzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBncmlkRGF0YTogZ3JpZERhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZENvbHVtbnM6IGdyaWRDb2x1bW5zLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNob3dUb29sQmFyOiBpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRSb3c6IHRoaXMuaGFuZGxlR3JpZFJvdyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBoYW5kbGVHcmlkQnRuQ2xpY2s6IHNlbGYuaGFuZGxlR3JpZEJ0bkNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHlsZTogc3R5bGVzLmdyaWQuaGVhZGVyVGFibGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnZGF0YS1ncmlkJyB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7IHRpdGxlOiAnU3VtbWEgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnc3VtbWEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LXN1bW1hJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHNlbGYuZG9jRGF0YS5zdW1tYSkgfHwgMCxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB3aWR0aDogJ2F1dG8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dE51bWJlciwgeyB0aXRsZTogJ0tcXHhFNGliZW1ha3MgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna2JtJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1rYm0nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHdpZHRoOiAnYXV0bycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IE51bWJlcihzZWxmLmRvY0RhdGEua2JtKSB8fCAwLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUlucHV0Q2hhbmdlXG4gICAgICAgICAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICBzZWxmLnN0YXRlLmdyaWRSb3dFZGl0ID8gdGhpcy5jcmVhdGVHcmlkUm93KHNlbGYpIDogbnVsbFxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQodC+0LfQtNCw0YHRgiDQutC+0LzQv9C+0L3QtdGCINGB0YLRgNC+0LrQuCDQs9GA0LjQtNCwXHJcbiAgICAgICAgICogQHJldHVybnMge1hNTH1cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnY3JlYXRlR3JpZFJvdycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBjcmVhdGVHcmlkUm93KHNlbGYpIHtcbiAgICAgICAgICAgIHZhciByb3cgPSBzZWxmLmdyaWRSb3dEYXRhID8gc2VsZi5ncmlkUm93RGF0YSA6IHt9LFxuICAgICAgICAgICAgICAgIHZhbGlkYXRlTWVzc2FnZSA9ICcnLFxuICAgICAgICAgICAgICAgIC8vIHNlbGYuc3RhdGUud2FybmluZ1xuICAgICAgICAgICAgYnV0dG9uT2tSZWFkT25seSA9IHZhbGlkYXRlTWVzc2FnZS5sZW5ndGggPiAwIHx8ICFzZWxmLnN0YXRlLmNoZWNrZWQsXG4gICAgICAgICAgICAgICAgbW9kYWxPYmplY3RzID0gWydidG5PaycsICdidG5DYW5jZWwnXTtcblxuICAgICAgICAgICAgaWYgKGJ1dHRvbk9rUmVhZE9ubHkpIHtcbiAgICAgICAgICAgICAgICAvLyDRg9Cx0LXRgNC10Lwg0LrQvdC+0L/QutGDINCe0LpcbiAgICAgICAgICAgICAgICBtb2RhbE9iamVjdHMuc3BsaWNlKDAsIDEpO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAoIXJvdykgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoJ2RpdicsIG51bGwpO1xuXG4gICAgICAgICAgICB2YXIgbm9tRGF0YSA9IFtdO1xuXG4gICAgICAgICAgICBub21EYXRhID0gc2VsZi5saWJzWydub21lbmNsYXR1cmUnXS5maWx0ZXIoZnVuY3Rpb24gKGxpYikge1xuICAgICAgICAgICAgICAgIGlmICghbGliLmRvayB8fCBsaWIuZG9rID09PSBMSUJET0spIHJldHVybiBsaWI7XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgeyBjbGFzc05hbWU6ICcubW9kYWxQYWdlJyB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgIE1vZGFsUGFnZSxcbiAgICAgICAgICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgICAgICAgICAgbW9kYWxPYmplY3RzOiBtb2RhbE9iamVjdHMsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdtb2RhbHBhZ2UtZ3JpZC1yb3cnLFxuICAgICAgICAgICAgICAgICAgICAgICAgc2hvdzogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIG1vZGFsUGFnZUJ0bkNsaWNrOiBzZWxmLm1vZGFsUGFnZUNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgbW9kYWxQYWdlTmFtZTogJ1JlYSBsaXNhbWluZSAvIHBhcmFuZGFtaW5lJyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ2dyaWQtcm93LWNvbnRhaW5lcicgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuc3RhdGUuZ3JpZFdhcm5pbmcubGVuZ3RoID8gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ3NwYW4nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLnN0YXRlLmdyaWRXYXJuaW5nXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgKSA6IG51bGwsXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdCwgeyB0aXRsZTogJ1RlZW51cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdub21pZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGxpYnM6ICdub21lbmNsYXR1cmUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhOiBub21EYXRhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiByb3cubm9taWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGxJZDogJ2lkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnbm9taWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwbGFjZWhvbGRlcjogJ1RlZW51c2Uga29vZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUdyaWRSb3dDaGFuZ2UgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7IHRpdGxlOiAnS29ndXMgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2tvZ3VzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IE51bWJlcihyb3cua29ndXMpLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYmluZERhdGE6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdrb2d1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiBzZWxmLmhhbmRsZUdyaWRSb3dJbnB1dCB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgdGl0bGU6ICdIaW5kICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdoaW5kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IE51bWJlcihyb3cuaGluZCksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBiaW5kRGF0YTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2hpbmQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogc2VsZi5oYW5kbGVHcmlkUm93SW5wdXQgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7IHRpdGxlOiAnS2JtLXRhOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna2JtdGEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHJvdy5rYm10YSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBiaW5kRGF0YTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2tibXRhJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlR3JpZFJvd0NoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgdGl0bGU6ICdLYm06ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrYm0nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHJvdy5rYm0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYmluZERhdGE6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdrYm0nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkJsdXI6IHNlbGYuaGFuZGxlR3JpZFJvd0lucHV0IH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dE51bWJlciwgeyB0aXRsZTogJ1N1bW1hOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnU3VtbWEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHJvdy5zdW1tYSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBiaW5kRGF0YTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3N1bW1hJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHNlbGYuaGFuZGxlR3JpZFJvd0lucHV0IH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdzcGFuJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbGlkYXRlTWVzc2FnZVxuICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINCy0LDQu9C40LTQsNGC0L7RgCDQtNC70Y8g0YHRgtGA0L7QutC4INCz0YDQuNC00LBcclxuICAgICAgICAgKiBAcGFyYW0gZ3JpZFJvd0RhdGEg0YHRgtGA0L7QutCwINCz0YDQuNC00LBcclxuICAgICAgICAgKiBAcmV0dXJucyB7c3RyaW5nfVxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdncmlkVmFsaWRhdGVGaWVsZHMnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gZ3JpZFZhbGlkYXRlRmllbGRzKCkge1xuICAgICAgICAgICAgdmFyIHdhcm5pbmcgPSAnJztcbiAgICAgICAgICAgIHZhciBkb2MgPSB0aGlzLnJlZnNbJ2RvY3VtZW50J107XG4gICAgICAgICAgICBpZiAoZG9jICYmIGRvYy5ncmlkUm93RGF0YSkge1xuXG4gICAgICAgICAgICAgICAgLy8g0YLQvtC70YzQutC+INC/0L7RgdC70LUg0L/RgNC+0LLQtdGA0LrQuCDRhNC+0YDQvNGLINC90LAg0LLQsNC70LjQtNC90L7RgdGC0YxcbiAgICAgICAgICAgICAgICBpZiAoZG9jLmdyaWRSb3dEYXRhICYmICFkb2MuZ3JpZFJvd0RhdGFbJ25vbWlkJ10pIHdhcm5pbmcgPSB3YXJuaW5nICsgJyDQmtC+0LQg0L7Qv9C10YDQsNGG0LjQuCc7XG4gICAgICAgICAgICAgICAgaWYgKCFkb2MuZ3JpZFJvd0RhdGFbJ2tvZ3VzJ10pIHdhcm5pbmcgPSB3YXJuaW5nICsgJyDQmtC+0LvQuNGH0LXRgdGC0LLQvic7XG4gICAgICAgICAgICAgICAgaWYgKCFkb2MuZ3JpZFJvd0RhdGFbJ3N1bW1hJ10pIHdhcm5pbmcgPSB3YXJuaW5nICsgJyDQodGD0LzQvNCwJztcblxuICAgICAgICAgICAgICAgIHRoaXMucmVjYWxjUm93U3VtbSgpO1xuICAgICAgICAgICAgICAgIHRoaXMucmVjYWxjRG9jU3VtbWEoJ3N1bW1hJyk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICByZXR1cm4gd2FybmluZztcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINC/0LXRgNC10YDQsNGB0YfQtdGCINGB0YPQvNC80Ysg0YHRgtGA0L7QutC4INC4INGA0LDRgdGH0LXRgiDQvdCw0LvQvtCz0LBcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVjYWxjUm93U3VtbScsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZWNhbGNSb3dTdW1tKCkge1xuICAgICAgICAgICAgdmFyIGRvYyA9IHRoaXMucmVmc1snZG9jdW1lbnQnXTtcblxuICAgICAgICAgICAgaWYgKCFPYmplY3Qua2V5cyhkb2MuZ3JpZFJvd0RhdGEpLmxlbmd0aCkge1xuICAgICAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIC8v0L/QvtC00YHRgtCw0LLQuNC8INC90LDQuNC80LXQvdC+0LLQsNC90LjQtSDRg9GB0LvQvtCz0YNcblxuICAgICAgICAgICAgdmFyIG5vbURhdGFOYW1lID0gZG9jLmxpYnNbJ25vbWVuY2xhdHVyZSddLmZpbHRlcihmdW5jdGlvbiAobGliKSB7XG4gICAgICAgICAgICAgICAgaWYgKGxpYi5pZCA9PT0gZG9jLmdyaWRSb3dEYXRhWydub21pZCddKSByZXR1cm4gbGliO1xuICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgIHZhciB2YXQgPSBub21EYXRhTmFtZVswXS52YXQgPyBOdW1iZXIobm9tRGF0YU5hbWVbMF0udmF0KSAvIDEwMCA6IDA7XG4gICAgICAgICAgICBpZiAoZG9jLmdyaWRSb3dEYXRhWydub21pZCddKSB7XG4gICAgICAgICAgICAgICAgZG9jLmdyaWRSb3dEYXRhWydrb29kJ10gPSBub21EYXRhTmFtZVswXS5rb29kO1xuICAgICAgICAgICAgICAgIGRvYy5ncmlkUm93RGF0YVsnbmltZXR1cyddID0gbm9tRGF0YU5hbWVbMF0ubmFtZTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgZG9jLmdyaWRSb3dEYXRhWydrb2d1cyddID0gTnVtYmVyKGRvYy5ncmlkUm93RGF0YS5rb2d1cyk7XG4gICAgICAgICAgICBkb2MuZ3JpZFJvd0RhdGFbJ2hpbmQnXSA9IE51bWJlcihkb2MuZ3JpZFJvd0RhdGEuaGluZCk7XG4gICAgICAgICAgICBkb2MuZ3JpZFJvd0RhdGFbJ2tibXRhJ10gPSBOdW1iZXIoZG9jLmdyaWRSb3dEYXRhWydrb2d1cyddKSAqIE51bWJlcihkb2MuZ3JpZFJvd0RhdGFbJ2hpbmQnXSk7XG4gICAgICAgICAgICBkb2MuZ3JpZFJvd0RhdGFbJ2tibSddID0gTnVtYmVyKGRvYy5ncmlkUm93RGF0YVsna2JtdGEnXSkgKiB2YXQ7XG4gICAgICAgICAgICBkb2MuZ3JpZFJvd0RhdGFbJ3N1bW1hJ10gPSBOdW1iZXIoZG9jLmdyaWRSb3dEYXRhWydrYm10YSddKSArIE51bWJlcihkb2MuZ3JpZFJvd0RhdGFbJ2tibSddKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINCf0LXRgNC10YDQsNGB0YfQtdGCINC40YLQvtCz0L7QstGL0YUg0YHRg9C80Lwg0LTQvtC60YPQvNC10L3RgtCwXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlY2FsY0RvY1N1bW1hJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlY2FsY0RvY1N1bW1hKCkge1xuICAgICAgICAgICAgdmFyIGRvYyA9IHRoaXMucmVmc1snZG9jdW1lbnQnXTtcblxuICAgICAgICAgICAgZG9jLmRvY0RhdGFbJ3N1bW1hJ10gPSAwO1xuICAgICAgICAgICAgZG9jLmRvY0RhdGFbJ2tibSddID0gMDtcbiAgICAgICAgICAgIGRvYy5kb2NEYXRhLmdyaWREYXRhLmZvckVhY2goZnVuY3Rpb24gKHJvdykge1xuICAgICAgICAgICAgICAgIGRvYy5kb2NEYXRhWydzdW1tYSddICs9IE51bWJlcihyb3dbJ3N1bW1hJ10pO1xuICAgICAgICAgICAgICAgIGRvYy5kb2NEYXRhWydrYm0nXSArPSBOdW1iZXIocm93WydrYm0nXSk7XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBBcnZlO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuQXJ2ZS5wcm9wVHlwZXMgPSB7XG4gICAgZG9jSWQ6IFByb3BUeXBlcy5udW1iZXIuaXNSZXF1aXJlZCxcbiAgICBpbml0RGF0YTogUHJvcFR5cGVzLm9iamVjdCxcbiAgICB1c2VyRGF0YTogUHJvcFR5cGVzLm9iamVjdFxufTtcblxubW9kdWxlLmV4cG9ydHMgPSBBcnZlO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9hcnYvYXJ2LmpzeFxuLy8gbW9kdWxlIGlkID0gMlxuLy8gbW9kdWxlIGNodW5rcyA9IDAgNCIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgZG9jUm93OiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ3JvdydcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBibHVlJ1xyXG4gICAgICAgICovXG4gICAgfSxcbiAgICBkb2NDb2x1bW46IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBmbGV4RGlyZWN0aW9uOiAnY29sdW1uJyxcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCB5ZWxsb3cnLFxyXG4gICAgICAgICovXG4gICAgICAgIHdpZHRoOiAnNTAlJ1xuICAgIH0sXG4gICAgZG9jOiB7XG4gICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ2NvbHVtbidcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBicm93bidcclxuICAgICAgICAqL1xuICAgIH0sXG4gICAgc3VtbWE6IHtcbiAgICAgICAgd2lkdGg6ICdhdXRvJ1xuICAgIH0sXG5cbiAgICBncmlkOiB7XG4gICAgICAgIG1haW5UYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuICAgICAgICBoZWFkZXJUYWJsZToge1xuICAgICAgICAgICAgd2lkdGg6ICcxMDAlJ1xuICAgICAgICB9LFxuXG4gICAgICAgIGdyaWRDb250YWluZXI6IHtcbiAgICAgICAgICAgIHdpZHRoOiAnMTAwJSdcbiAgICAgICAgfVxuXG4gICAgfSxcblxuICAgIGdyaWRSb3c6IHtcbiAgICAgICAgLypcclxuICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBibGFjaycsXHJcbiAgICAgICAgKi9cbiAgICAgICAgYmFja2dyb3VuZENvbG9yOiAnd2hpdGUnLFxuICAgICAgICBwb3NpdGlvbjogJ3JlbGF0aXZlJyxcbiAgICAgICAgbWFyZ2luOiAnMTAlIDMwJSAxMCUgMzAlJyxcbiAgICAgICAgd2lkdGg6ICdhdXRvJyxcbiAgICAgICAgb3BhY2l0eTogJzEnLFxuICAgICAgICB0b3A6ICcxMDBweCdcbiAgICB9XG5cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2Fydi9hcnZlLnN0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMTYwXG4vLyBtb2R1bGUgY2h1bmtzID0gMCA0IiwiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uIChkb2NUeXBlSWQpIHtcbiAgICAvLyDQstC30LDQstC40YHQuNC80L7RgdGC0Lgg0L7RgiDRgtC40L/QsCDQtNC+0LrRg9C80LXQvdGC0LAg0LLQtdGA0L3QtdGCINC60L7QvNC/0L7QvdC10L3RgiDQtNC+0LrRg9C80LXQvdGC0LBcblxuICAgIGNvbnNvbGUubG9nKCdyZXR1cm5Eb2NDb21wb25lbnQ6JyArIGRvY1R5cGVJZCk7XG4gICAgdmFyIGNvbXBvbmVudCA9IHt9O1xuXG4gICAgc3dpdGNoIChkb2NUeXBlSWQpIHtcbiAgICAgICAgY2FzZSAnUEFMSyc6XG4gICAgICAgICAgICBjb21wb25lbnQgPSByZXF1aXJlKCcuLi9mcm9udGVuZC9kb2NzL3BhbGtfb3Blci5qc3gnKTtcbiAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICBkZWZhdWx0OlxuICAgICAgICAgICAgY29tcG9uZW50ID0gcmVxdWlyZSgnLi4vZnJvbnRlbmQvZG9jcy9hcnYvYXJ2LmpzeCcpO1xuICAgIH1cbiAgICByZXR1cm4gY29tcG9uZW50O1xufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL21pZGRsZXdhcmUvcmV0dXJuRG9jQ29tcG9uZW50LmpzXG4vLyBtb2R1bGUgaWQgPSAxNzJcbi8vIG1vZHVsZSBjaHVua3MgPSA0IiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIEZvcm0gPSByZXF1aXJlKCcuLi9jb21wb25lbnRzL2Zvcm0uanMnKTtcbnZhciBQYWdlTGFiZWwgPSByZXF1aXJlKCcuLi9jb21wb25lbnRzL3BhZ2VfbGFiZWwnKTtcblxudmFyIHBhZ2VzID0gWydQYWdlMScsICdQYWdlMiddO1xuXG52YXIgUGFsayA9IFJlYWN0LmNyZWF0ZUNsYXNzKHtcbiAgICBkaXNwbGF5TmFtZTogJ1BhbGsnLFxuXG4gICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgRm9ybSxcbiAgICAgICAgICAgIHsgcGFnZXM6IHBhZ2VzIH0sXG4gICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdzcGFuJyxcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICcgUGFsayAnXG4gICAgICAgICAgICApXG4gICAgICAgICk7XG4gICAgfSB9KTtcblxubW9kdWxlLmV4cG9ydHMgPSBQYWxrO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9wYWxrX29wZXIuanN4XG4vLyBtb2R1bGUgaWQgPSAxNzNcbi8vIG1vZHVsZSBjaHVua3MgPSA0IiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpLFxuICAgIGZsdXggPSByZXF1aXJlKCdmbHV4aWZ5Jyk7XG5cbnZhciBQYWdlTGFiZWwgPSByZXF1aXJlKCcuL3BhZ2VfbGFiZWwnKTtcblxudmFyIEZvcm0gPSBSZWFjdC5jcmVhdGVDbGFzcyh7XG4gICAgZGlzcGxheU5hbWU6ICdGb3JtJyxcblxuICAgIGdldEluaXRpYWxTdGF0ZTogZnVuY3Rpb24gZ2V0SW5pdGlhbFN0YXRlKCkge1xuICAgICAgICB2YXIgcGFnZXMgPSBbeyBwYWdlTmFtZTogJ1BhZ2UnIH1dO1xuICAgICAgICBpZiAodGhpcy5wcm9wcy5wYWdlcykge1xuICAgICAgICAgICAgcGFnZXMgPSB0aGlzLnByb3BzLnBhZ2VzO1xuICAgICAgICB9XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBwYWdlczogdGhpcy5wcm9wcy5wYWdlc1xuICAgICAgICB9O1xuICAgIH0sXG5cbiAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgdmFyIHBhZ2VzID0gdGhpcy5zdGF0ZS5wYWdlcztcbiAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoJ2RpdicsIHsgY2xhc3NOYW1lOiAnY29udGFpbmVyJyB9LCBwYWdlcy5tYXAoZnVuY3Rpb24gKHBhZ2UsIGlkeCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUGFnZUxhYmVsLCB7IGtleTogaWR4LCBwYWdlSWR4OiBpZHggfSwgcGFnZSk7XG4gICAgICAgIH0pLCBSZWFjdC5jcmVhdGVFbGVtZW50KCdkaXYnLCB7IGNsYXNzTmFtZTogJ3BhZ2UnIH0sIFJlYWN0LmNyZWF0ZUVsZW1lbnQoJ2Zvcm0nLCBudWxsLCB0aGlzLnByb3BzLmNoaWxkcmVuKSkpO1xuICAgIH1cbn0pO1xuXG5tb2R1bGUuZXhwb3J0cyA9IEZvcm07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9jb21wb25lbnRzL2Zvcm0uanNcbi8vIG1vZHVsZSBpZCA9IDE3NFxuLy8gbW9kdWxlIGNodW5rcyA9IDQiLCIndXNlIHN0cmljdCc7XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0JyksXG4gICAgZmx1eCA9IHJlcXVpcmUoJ2ZsdXhpZnknKTtcblxudmFyIFBhZ2VMYWJlbCA9IFJlYWN0LmNyZWF0ZUNsYXNzKHtcbiAgICBkaXNwbGF5TmFtZTogJ1BhZ2VMYWJlbCcsXG4gICAgZ2V0SW5pdGlhbFN0YXRlOiBmdW5jdGlvbiBnZXRJbml0aWFsU3RhdGUoKSB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICAgICAgfTtcbiAgICB9LFxuXG4gICAgY29tcG9uZW50RGlkTW91bnQ6IGZ1bmN0aW9uIGNvbXBvbmVudERpZE1vdW50KCkge1xuICAgICAgICB2YXIgc2VsZiA9IHRoaXM7XG4gICAgICAgIC8vICAgICAgY29uc29sZS5sb2coJ3BhZ2UgbGFiZWwgY29tcG9uZW50V2lsbE1vdW50JylcbiAgICAgICAgZmx1eC5zdG9yZXMuZG9jU3RvcmUub24oJ2NoYW5nZTplZGl0ZWQnLCBmdW5jdGlvbiAobmV3VmFsdWUsIHByZXZpb3VzVmFsdWUpIHtcbiAgICAgICAgICAgIHNlbGYuc2V0U3RhdGUoeyBkaXNhYmxlZDogbmV3VmFsdWUgfSk7XG4gICAgICAgIH0pO1xuICAgIH0sXG5cbiAgICBoYW5kbGVDbGljazogZnVuY3Rpb24gaGFuZGxlQ2xpY2socGFnZSkge1xuICAgICAgICAvLyDQvtCx0YDQsNCx0L7RgtGH0LjQuiDQvdCwINGB0L7QsdGL0YLQuNC1INC60LvQuNC6LCDQv9C+0LTQs9GA0YPQttCw0LXQvCDRgdCy0Y/Qt9Cw0L3QvdGL0Lkg0LTQvtC60YPQvNC10L3RglxuICAgICAgICAvLyAgICAgICBhbGVydCgnY2xpY2s6JyArIHBhZ2VOYW1lKTtcbiAgICAgICAgLy8gZG9jVHlwZUlkOiBkb2MuZG9jX3R5cGUsIGRvY0lkOmRvYy5pZCwgcGFnZU5hbWU6J0xhdXNlbmQgaWQ6JyArIGRvYy5pZFxuXG4gICAgICAgIGlmICh0aGlzLnN0YXRlLmRpc2FibGVkKSB7XG4gICAgICAgICAgICBjb25zb2xlLmxvZygncGFnZSBkaXNhYmxlZCcpO1xuICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgaWYgKHBhZ2UuZG9jSWQpIHtcbiAgICAgICAgICAgIGNvbnNvbGUubG9nKCdoYW5kbGVDbGljayBwYWdlLmRvY1R5cGVJZCAlcywgcGFnZS5kb2NJZCAlbicpO1xuICAgICAgICAgICAgdmFyIHVybCA9IFwiL2RvY3VtZW50L1wiICsgcGFnZS5kb2NUeXBlSWQgKyBwYWdlLmRvY0lkO1xuICAgICAgICAgICAgZG9jdW1lbnQubG9jYXRpb24uaHJlZiA9IHVybDtcbiAgICAgICAgfVxuICAgIH0sXG5cbiAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgdmFyIGNsYXNzTmFtZSA9ICdwYWdlTGFiZWwnO1xuXG4gICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KCdsYWJlbCcsIHsgY2xhc3NOYW1lOiBjbGFzc05hbWUsIG9uQ2xpY2s6IHRoaXMuaGFuZGxlQ2xpY2suYmluZCh0aGlzLCB0aGlzLnByb3BzLmNoaWxkcmVuKSwgZGlzYWJsZWQ6IHRoaXMuc3RhdGUuZGlzYWJsZWQgfSwgdGhpcy5wcm9wcy5jaGlsZHJlbi5wYWdlTmFtZSwgJyAnKTtcbiAgICB9XG59KTtcblxubW9kdWxlLmV4cG9ydHMgPSBQYWdlTGFiZWw7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9jb21wb25lbnRzL3BhZ2VfbGFiZWwuanNcbi8vIG1vZHVsZSBpZCA9IDE3NVxuLy8gbW9kdWxlIGNodW5rcyA9IDQiXSwibWFwcGluZ3MiOiI7Ozs7OztBQUFBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDZkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDbGJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUN2REE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2hCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUN2QkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzVCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7OzsiLCJzb3VyY2VSb290IjoiIn0=