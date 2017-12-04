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

	var React = __webpack_require__(13),
	    flux = __webpack_require__(14);

	var Form = __webpack_require__(19),
	    InputText = __webpack_require__(23),
	    InputDate = __webpack_require__(25),
	    InputNumber = __webpack_require__(27),
	    DocCommon = __webpack_require__(29),
	    Select = __webpack_require__(31),

	//    SelectData = require('../../components/select-data/select-data.jsx'),
	TextArea = __webpack_require__(33),
	    DataGrid = __webpack_require__(35),
	    GridButtonAdd = __webpack_require__(102),
	    GridButtonEdit = __webpack_require__(105),
	    GridButtonDelete = __webpack_require__(106),
	    DokProp = __webpack_require__(107),
	    relatedDocuments = __webpack_require__(108),
	    ToolbarContainer = __webpack_require__(109),
	    MenuToolBar = __webpack_require__(111),
	    DocToolBar = __webpack_require__(118),
	    validateForm = __webpack_require__(125),
	    ModalPage = __webpack_require__(126),
	    styles = __webpack_require__(128);

	var LIBDOK = 'ARV',
	    LIBRARIES = ['asutused', 'kontod', 'dokProps', 'users', 'aa', 'tunnus', 'project', 'nomenclature'];

	// Create a store
	var docStore = __webpack_require__(129);

	var now = new Date();

	var Arve = function (_React$PureComponent) {
	    _inherits(Arve, _React$PureComponent);

	    function Arve(props) {
	        _classCallCheck(this, Arve);

	        var _this = _possibleConstructorReturn(this, (Arve.__proto__ || Object.getPrototypeOf(Arve)).call(this, props));

	        _this.state = {
	            edited: _this.props.data.row.id == 0,
	            showMessageBox: 'none',
	            relations: _this.props.data.relations,
	            gridRowEdit: false,
	            gridRowEvent: null,
	            checked: false,
	            warning: ''
	        };

	        _this.docData = _this.props.data.row;
	        _this.gridData = _this.props.data.details;
	        _this.gridConfig = _this.props.data.gridConfig;
	        _this.gridRowData = null;
	        _this.libs = _this.createLibs();

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
	        _this.handleToolbarEvents = _this.handleToolbarEvents.bind(_this);
	        _this.validation = _this.validation.bind(_this);

	        _this.modalPageClick = _this.modalPageClick.bind(_this);
	        _this.handleGridBtnClick = _this.handleGridBtnClick.bind(_this);
	        _this.addRow = _this.addRow.bind(_this);
	        _this.handleGridRowChange = _this.handleGridRowChange.bind(_this);
	        _this.validateGridRow = _this.validateGridRow.bind(_this);
	        _this.handleGridRowInput = _this.handleGridRowInput.bind(_this);
	        _this.createGridRow = _this.createGridRow.bind(_this);
	        _this.handleInputChange = _this.handleInputChange.bind(_this);
	        return _this;
	    }

	    _createClass(Arve, [{
	        key: 'componentDidMount',
	        value: function componentDidMount() {
	            var _this2 = this;

	            if (window) {
	                window.addEventListener('beforeunload', this.componentCleanup);
	            }

	            // пишем исходные данные в хранилище, регистрируем обработчики событий
	            var self = this,
	                data = Object.assign({}, self.props.data.row),
	                details = Object.assign([], self.props.data.details),
	                gridConfig = self.props.data.gridConfig;

	            // сохраняем данные в хранилище
	            flux.doAction('dataChange', data);
	            flux.doAction('docIdChange', data.id);
	            flux.doAction('detailsChange', details); // данные грида
	            flux.doAction('gridConfigChange', gridConfig); // данные грида

	            // грузим справочники
	            LIBRARIES.forEach(function (lib) {
	                flux.doAction("loadLibs", lib);
	            });

	            // если новый документ (id == 0)

	            if (data.id == 0) {
	                flux.doAction('editedChange', true);
	                flux.doAction('savedChange', false);
	            }

	            // отслеживаем режим редактирования
	            docStore.on('change:edited', function (newValue, previousValue) {
	                if (newValue !== previousValue) {
	                    self.setState({ edited: newValue });
	                }
	            });

	            docStore.on('change:libs', function (newValue) {
	                var isChanged = false,
	                    libsData = _this2.libs;

	                if (newValue.length > 0) {

	                    newValue.forEach(function (lib) {
	                        if (lib.id === 'dokProps') {
	                            // оставим только данные этого документа

	                        }
	                        if (_this2.libs[lib.id] && lib.data.length > 0) {
	                            libsData[lib.id] = lib.data;
	                            isChanged = true;
	                        }
	                    });
	                }

	                if (isChanged) {
	                    _this2.libs = libsData;
	                    _this2.forceUpdate();
	                }
	            });
	        }

	        /**
	         * снимет все подписки
	         */

	    }, {
	        key: 'componentCleanup',
	        value: function componentCleanup() {
	            /*
	                    docStore.off('change:edited');
	                    docStore.off('change:libs');
	            */
	        }
	    }, {
	        key: 'componentWillUnmount',
	        value: function componentWillUnmount() {
	            this.componentCleanup();
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            // формируем зависимости
	            relatedDocuments(this);

	            var isEditMode = this.state.edited,
	                validationMessage = this.validation();

	            var btnParams = {
	                btnStart: {
	                    show: true
	                }
	            };

	            return React.createElement(
	                'div',
	                null,
	                MenuToolBar(btnParams, this.props.userData),
	                React.createElement(
	                    Form,
	                    { pages: this.pages,
	                        ref: 'form',
	                        handlePageClick: this.handlePageClick,
	                        disabled: isEditMode },
	                    React.createElement(
	                        ToolbarContainer,
	                        { ref: 'toolbar-container' },
	                        React.createElement(
	                            'div',
	                            { className: 'doc-toolbar-warning' },
	                            validationMessage ? React.createElement(
	                                'span',
	                                null,
	                                validationMessage
	                            ) : null
	                        ),
	                        React.createElement(
	                            'div',
	                            null,
	                            React.createElement(DocToolBar, { bpm: this.props.bpm,
	                                ref: 'doc-toolbar',
	                                edited: isEditMode,
	                                docStatus: this.docData.doc_status,
	                                validator: this.validation,
	                                eventHandler: this.handleToolbarEvents })
	                        )
	                    ),
	                    React.createElement(
	                        'div',
	                        { style: styles.doc },
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(DocCommon, {
	                                ref: 'doc-common',
	                                data: this.docData,
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
	                                    value: this.docData.number,
	                                    readOnly: !isEditMode,
	                                    onChange: this.handleInputChange }),
	                                React.createElement(InputDate, { title: 'Kuup\xE4ev ',
	                                    name: 'kpv', value: this.docData.kpv,
	                                    ref: 'input-kpv',
	                                    readOnly: !isEditMode,
	                                    onChange: this.handleInputChange }),
	                                React.createElement(InputDate, { title: 'T\xE4htaeg ',
	                                    name: 'tahtaeg',
	                                    value: this.docData.tahtaeg,
	                                    ref: 'input-tahtaeg',
	                                    readOnly: !isEditMode,
	                                    onChange: this.handleInputChange }),
	                                React.createElement(Select, { title: 'Asutus',
	                                    name: 'asutusid',
	                                    libs: 'asutused',
	                                    data: this.libs['asutused'],
	                                    value: this.docData.asutusid,
	                                    defaultValue: this.docData.asutus,
	                                    ref: 'select-asutusid',
	                                    btnDelete: isEditMode,
	                                    onChange: this.handleInputChange,
	                                    readOnly: !isEditMode }),
	                                React.createElement(InputText, { title: 'Lisa ',
	                                    name: 'lisa',
	                                    value: this.docData.lisa,
	                                    ref: 'input-lisa',
	                                    readOnly: !isEditMode,
	                                    onChange: this.handleInputChange })
	                            ),
	                            React.createElement(
	                                'div',
	                                { style: styles.docColumn },
	                                React.createElement(DokProp, { title: 'Konteerimine: ',
	                                    name: 'doklausid',
	                                    libs: 'dokProps',
	                                    value: this.docData.doklausid,
	                                    defaultValue: this.docData.dokprop,
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
	                                onChange: this.handleInputChange,
	                                value: this.docData.muud || '',
	                                readOnly: !isEditMode })
	                        ),
	                        isEditMode ? React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(
	                                ToolbarContainer,
	                                {
	                                    ref: 'grid-toolbar-container',
	                                    position: 'left' },
	                                React.createElement(GridButtonAdd, { onClick: this.handleGridBtnClick, ref: 'grid-button-add' }),
	                                React.createElement(GridButtonEdit, { onClick: this.handleGridBtnClick, ref: 'grid-button-edit' }),
	                                React.createElement(GridButtonDelete, { onClick: this.handleGridBtnClick, ref: 'grid-button-delete' })
	                            )
	                        ) : null,
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(DataGrid, { source: 'details',
	                                gridData: this.gridData,
	                                gridColumns: this.gridConfig,
	                                handleGridRow: this.handleGridRow,
	                                readOnly: !isEditMode,
	                                ref: 'data-grid' })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputText, { title: 'Summa ',
	                                name: 'summa',
	                                ref: 'input-summa',
	                                value: this.docData.summa,
	                                disabled: true,
	                                onChange: this.handleInputChange,
	                                pattern: '^[0-9]+(\\.[0-9]{1,4})?$' }),
	                            React.createElement(InputText, { title: 'K\xE4ibemaks ',
	                                name: 'kbm',
	                                ref: 'input-kbm',
	                                disabled: true,
	                                value: this.docData.kbm,
	                                onChange: this.handleInputChange,
	                                pattern: '^[0-9]+(\\.[0-9]{1,4})?$' })
	                        ),
	                        this.state.gridRowEdit ? this.createGridRow() : null
	                    )
	                )
	            );
	        }

	        /**
	         * валидация формы
	         */

	    }, {
	        key: 'validation',
	        value: function validation() {
	            if (!this.state.edited) return '';

	            var requiredFields = this.requiredFields;
	            return __webpack_require__(125)(this, requiredFields);
	        }

	        /**
	         * отработаем Ok из модального окна
	         * @param btnEvent
	         */

	    }, {
	        key: 'modalPageClick',
	        value: function modalPageClick(btnEvent) {
	            var _this3 = this;

	            if (btnEvent == 'Ok') {

	                // ищем по ид строку в данных грида, если нет, то добавим строку
	                if (!this.gridData.some(function (row) {
	                    if (row.id === _this3.gridRowData.id) return true;
	                })) {
	                    // вставка новой строки
	                    this.gridData.splice(0, 0, this.gridRowData);
	                } else {
	                    this.gridData = this.gridData.map(function (row) {
	                        if (row.id === _this3.gridRowData.id) {
	                            // нашли, замещаем
	                            return _this3.gridRowData;
	                        } else {
	                            return row;
	                        }
	                    });
	                }
	            }

	            this.recalcDocSumma();
	            this.setState({ gridRowEdit: false });
	        }

	        /**
	         * Обработчик события клик по вкладке
	         * @param page
	         */

	    }, {
	        key: 'handlePageClick',
	        value: function handlePageClick(page) {
	            if (page.docId) {
	                document.location.href = "/document/" + page.docTypeId + page.docId;
	            }
	        }

	        /**
	         * метод вызывается при выборе задачи
	         * @param e
	         */

	    }, {
	        key: 'handleSelectTask',
	        value: function handleSelectTask(e) {
	            return e.target.value;
	        }

	        /**
	         *  toolbar event handler
	         * @param event
	         */

	    }, {
	        key: 'handleToolbarEvents',
	        value: function handleToolbarEvents(event) {
	            switch (event) {
	                case 'CANCEL':
	                    this.docData = JSON.parse(flux.stores.docStore.backup.docData); // восстановим данные
	                    this.gridData = JSON.parse(flux.stores.docStore.backup.gridData);

	                    if (this.state.warning !== '') {
	                        this.setState({ warning: '' });
	                    } else {
	                        this.forceUpdate();
	                    }
	                    break;
	                default:
	                    console.error('handleToolbarEvents, no event handler for ', event);
	            }
	        }

	        /**
	         * Обработчик изменений инпутов
	         * @param inputName
	         * @param inputValue
	         * @returns {boolean}
	         */

	    }, {
	        key: 'handleInputChange',
	        value: function handleInputChange(inputName, inputValue) {

	            // изменения допустимы только в режиме редактирования
	            if (!this.state.edited) {
	                console.error('not in edite mode');
	                return false;
	            }

	            this.docData[inputName] = inputValue;
	            this.forceUpdate();
	        }

	        /**
	         * Подготовка параметров для панели инструментов
	         * @param isEditMode
	         * @returns {{btnAdd: {show: boolean, disabled: *}, btnEdit: {show: boolean, disabled: *}, btnPrint: {show: boolean, disabled: boolean}, btnSave: {show: *, disabled: boolean}}}
	         */

	    }, {
	        key: 'prepaireToolBarParameters',
	        value: function prepaireToolBarParameters(isEditMode) {
	            return {
	                btnAdd: {
	                    show: !isEditMode,
	                    disabled: isEditMode
	                },
	                btnEdit: {
	                    show: !isEditMode,
	                    disabled: isEditMode
	                },
	                btnPrint: {
	                    show: true,
	                    disabled: true
	                },
	                btnSave: {
	                    show: isEditMode,
	                    disabled: false
	                }
	            };
	        }

	        /**
	         * обработчик для событий клик панели инструментов грида
	         * @param btnName
	         */

	    }, {
	        key: 'handleGridBtnClick',
	        value: function handleGridBtnClick(btnName) {
	            switch (btnName) {
	                case 'add':
	                    this.addRow();
	                    break;
	                case 'edit':
	                    this.editRow();
	                    break;
	                case 'delete':
	                    this.deleteRow();
	                    break;
	            }
	        }

	        /**
	         * удалит активную строку
	         */

	    }, {
	        key: 'deleteRow',
	        value: function deleteRow() {
	            var gridActiveRow = this.refs['data-grid'].state.activeRow;

	            this.gridData.splice(gridActiveRow, 1);

	            // перерасчет итогов
	            this.recalcDocSumma();

	            // изменим состояние
	            this.forceUpdate();
	        }

	        /**
	         * откроет активную строку для редактирования
	         */

	    }, {
	        key: 'editRow',
	        value: function editRow() {
	            this.gridRowData = this.gridData[this.refs['data-grid'].state.activeRow];

	            // откроем модальное окно для редактирования
	            this.setState({ gridRowEdit: true, gridRowEvent: 'edit' });
	        }

	        /**
	         * добавит в состояние новую строку
	         */

	    }, {
	        key: 'addRow',
	        value: function addRow() {
	            var newRow = {};

	            for (var i = 0; i < this.gridConfig.length; i++) {
	                var field = this.gridConfig[i].id;
	                newRow[field] = '';
	            }

	            newRow.id = 'NEW' + Math.random(); // генерим новое ид

	            this.gridRowData = newRow;
	            // откроем модальное окно для редактирования
	            this.setState({ gridRowEdit: true, gridRowEvent: 'add' });
	        }

	        /**
	         * Создаст компонет строки грида
	         * @returns {XML}
	         */

	    }, {
	        key: 'createGridRow',
	        value: function createGridRow() {
	            var validateMessage = '',
	                modalObjects = ['btnOk', 'btnCancel'],
	                buttonOkReadOnly = validateMessage.length > 0 || !this.state.checked;

	            if (buttonOkReadOnly) {
	                // уберем кнопку Ок
	                modalObjects.splice(0, 1);
	            }

	            if (!this.gridRowData) return React.createElement('div', null);

	            var nomData = this.libs['nomenclature'].filter(function (lib) {
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
	                        modalPageBtnClick: this.modalPageClick,
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
	                                readOnly: false,
	                                value: this.gridRowData.nomid,
	                                defaultValue: this.gridRowData.kood,
	                                ref: 'nomid',
	                                placeholder: 'Teenuse kood',
	                                onChange: this.handleGridRowChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Kogus ',
	                                name: 'kogus',
	                                value: Number(this.gridRowData.kogus),
	                                readOnly: false,
	                                disabled: false,
	                                bindData: false,
	                                ref: 'kogus',
	                                className: 'ui-c2',
	                                onChange: this.handleGridRowInput })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Hind ',
	                                name: 'hind',
	                                value: Number(this.gridRowData.hind),
	                                readOnly: false,
	                                disabled: false,
	                                bindData: false,
	                                ref: 'hind',
	                                className: 'ui-c2',
	                                onChange: this.handleGridRowInput })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Kbm-ta: ',
	                                name: 'kbmta',
	                                value: Number(this.gridRowData.kbmta),
	                                disabled: true,
	                                bindData: false,
	                                ref: 'kbmta',
	                                className: 'ui-c2',
	                                onChange: this.handleGridRowChange })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Kbm: ',
	                                name: 'kbm',
	                                value: Number(this.gridRowData.kbm),
	                                disabled: true,
	                                bindData: false,
	                                ref: 'kbm',
	                                className: 'ui-c2',
	                                onBlur: this.handleGridRowInput })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.docRow },
	                            React.createElement(InputNumber, { title: 'Summa: ',
	                                name: 'Summa',
	                                value: Number(this.gridRowData.summa),
	                                disabled: true,
	                                bindData: false,
	                                ref: 'summa',
	                                className: 'ui-c2',
	                                onChange: this.handleGridRowInput })
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
	         * отслеживаем изменения данных на форм
	         * @param name
	         * @param value
	         */

	    }, {
	        key: 'handleGridRowChange',
	        value: function handleGridRowChange(name, value) {
	            var _this4 = this;

	            if (value !== this.gridRowData[name] && name === 'nomid') {
	                // произошло изменение услуги, обнулим значения
	                this.gridRowData['kogus'] = 0;
	                this.gridRowData['hind'] = 0;
	                this.gridRowData['summa'] = 0;
	                this.gridRowData['kbm'] = 0;
	                this.gridRowData['kbmta'] = 0;
	                this.gridRowData['nomid'] = value;
	            }
	            // ищем по справочнику поля код и наименование

	            var libData = this.libs['nomenclature'];
	            libData.forEach(function (row) {
	                if (row.id == value) {
	                    _this4.gridRowData['kood'] = row.kood;
	                    _this4.gridRowData['nimetus'] = row.name;
	                }
	            });

	            this.gridRowData[name] = value;
	            //        this.forceUpdate();
	            this.validateGridRow();
	        }

	        /**
	         * Обработчик для строки грида
	         * @param name
	         * @param value
	         */

	    }, {
	        key: 'handleGridRowInput',
	        value: function handleGridRowInput(name, value) {
	            this.gridRowData[name] = value;

	            // пересчет сумм
	            this.recalcRowSumm();
	            //        this.forceUpdate();
	            this.validateGridRow();
	        }

	        /**
	         * перерасчет суммы строки и расчет налога
	         */

	    }, {
	        key: 'recalcRowSumm',
	        value: function recalcRowSumm() {
	            this.gridRowData['kogus'] = Number(this.gridRowData.kogus);
	            this.gridRowData['hind'] = Number(this.gridRowData.hind);
	            this.gridRowData['kbmta'] = Number(this.gridRowData['kogus']) * Number(this.gridRowData['hind']);
	            this.gridRowData['kbm'] = Number(this.gridRowData['kbmta'] * 0.20); // @todo врменно
	            this.gridRowData['summa'] = Number(this.gridRowData['kbmta']) + Number(this.gridRowData['kbm']);
	        }

	        /**
	         * Перерасчет итоговых сумм документа
	         */

	    }, {
	        key: 'recalcDocSumma',
	        value: function recalcDocSumma() {
	            var _this5 = this;

	            this.docData['summa'] = 0;
	            this.docData['kbm'] = 0;
	            this.gridData.forEach(function (row) {
	                _this5.docData['summa'] += Number(row['summa']);
	                _this5.docData['kbm'] += Number(row['kbm']);
	            });
	        }

	        /**
	         * will check values on the form and return string with warning
	         */

	    }, {
	        key: 'validateGridRow',
	        value: function validateGridRow() {
	            var warning = '';

	            // только после проверки формы на валидность
	            if (!this.gridRowData['nomid']) warning = warning + ' код услуги';
	            if (!this.gridRowData['kogus']) warning = warning + ' кол-во';
	            if (!this.gridRowData['hind']) warning = warning + ' цена';

	            if (warning.length > 2) {
	                // есть проблемы
	                warning = 'Отсутсвуют данные:' + warning;
	            }
	            this.setState({ checked: true, warning: warning });
	        }

	        /**
	         * вернет объект библиотек документа
	         * @returns {{}}
	         */

	    }, {
	        key: 'createLibs',
	        value: function createLibs() {
	            var libs = {};
	            LIBRARIES.forEach(function (lib) {
	                libs[lib] = [];
	            });
	            return libs;
	        }
	    }]);

	    return Arve;
	}(React.PureComponent);

	Arve.propTypes = {
	    data: PropTypes.object.isRequired,
	    bpm: PropTypes.array,
	    edited: PropTypes.bool,
	    showMessageBox: PropTypes.string,
	    gridData: PropTypes.array,
	    relations: PropTypes.array,
	    gridConfig: PropTypes.array,
	    gridRowEdit: PropTypes.bool,
	    gridRowEvent: PropTypes.string,
	    gridRowData: PropTypes.object,
	    libs: PropTypes.object,
	    checked: PropTypes.bool,
	    warning: PropTypes.string

	};

	/*
	 Arve.defaultProps = {
	 disabled: false,
	 show: true
	 };
	 */

	module.exports = Arve;

/***/ }),

/***/ 128:
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
	    flux = __webpack_require__(14);

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
	    flux = __webpack_require__(14);

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
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZG9jLmpzIiwic291cmNlcyI6WyJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvYXJ2ZS9hcnZlLmpzeD81MjJiIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvYXJ2ZS9hcnZlLnN0eWxlcy5qcz8zYTcwIiwid2VicGFjazovLy8uL21pZGRsZXdhcmUvcmV0dXJuRG9jQ29tcG9uZW50LmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MvcGFsa19vcGVyLmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9jb21wb25lbnRzL2Zvcm0uanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvY29tcG9uZW50cy9wYWdlX2xhYmVsLmpzIl0sInNvdXJjZXNDb250ZW50IjpbIid1c2Ugc3RyaWN0JztcblxudmFyIFJlYWN0RE9NID0gcmVxdWlyZSgncmVhY3QtZG9tJyk7XG5cbi8vINC00LDQvdC90YvQtSDQtNC70Y8g0YXRgNCw0L3QuNC70LjRidCwXG5sb2NhbFN0b3JhZ2VbJ2RvY1N0b3JlJ10gPSBzdG9yZURhdGE7XG5zdG9yZURhdGEgPSBKU09OLnBhcnNlKHN0b3JlRGF0YSk7XG51c2VyRGF0YSA9IEpTT04ucGFyc2UodXNlckRhdGEpO1xuXG4vLyDRgdC+0LfQtNCw0LXQvCDQvtCx0YDQsNCx0L7RgtGH0LjQuiDRgdC+0LHRi9GC0LjRjyDQvdCwINC40LfQvNC10L3QtdC90LjQtSDQtNCw0L3QvdGFXG5cblxuLy8g0LfQsNC/0YDQvtGB0LjQvCDQutC+0LzQv9C+0L3QtdC90YIg0LTQvtC60YPQvNC10L3RgtCwINC/0L4g0LXQs9C+INGC0LjQv9GDXG52YXIgRG9jID0gcmVxdWlyZSgnLi4vbWlkZGxld2FyZS9yZXR1cm5Eb2NDb21wb25lbnQnKShzdG9yZURhdGEuZG9jVHlwZUlkKTtcblxuUmVhY3RET00uaHlkcmF0ZShSZWFjdC5jcmVhdGVFbGVtZW50KERvYywgeyBkYXRhOiBzdG9yZURhdGEuZGF0YSwgYnBtOiBzdG9yZURhdGEuYnBtLCB1c2VyRGF0YTogdXNlckRhdGEgfSksIGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCdkb2MnKSk7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2MuanNcbi8vIG1vZHVsZSBpZCA9IDBcbi8vIG1vZHVsZSBjaHVua3MgPSA0IiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgX2NyZWF0ZUNsYXNzID0gZnVuY3Rpb24gKCkgeyBmdW5jdGlvbiBkZWZpbmVQcm9wZXJ0aWVzKHRhcmdldCwgcHJvcHMpIHsgZm9yICh2YXIgaSA9IDA7IGkgPCBwcm9wcy5sZW5ndGg7IGkrKykgeyB2YXIgZGVzY3JpcHRvciA9IHByb3BzW2ldOyBkZXNjcmlwdG9yLmVudW1lcmFibGUgPSBkZXNjcmlwdG9yLmVudW1lcmFibGUgfHwgZmFsc2U7IGRlc2NyaXB0b3IuY29uZmlndXJhYmxlID0gdHJ1ZTsgaWYgKFwidmFsdWVcIiBpbiBkZXNjcmlwdG9yKSBkZXNjcmlwdG9yLndyaXRhYmxlID0gdHJ1ZTsgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRhcmdldCwgZGVzY3JpcHRvci5rZXksIGRlc2NyaXB0b3IpOyB9IH0gcmV0dXJuIGZ1bmN0aW9uIChDb25zdHJ1Y3RvciwgcHJvdG9Qcm9wcywgc3RhdGljUHJvcHMpIHsgaWYgKHByb3RvUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IucHJvdG90eXBlLCBwcm90b1Byb3BzKTsgaWYgKHN0YXRpY1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLCBzdGF0aWNQcm9wcyk7IHJldHVybiBDb25zdHJ1Y3RvcjsgfTsgfSgpO1xuXG5mdW5jdGlvbiBfY2xhc3NDYWxsQ2hlY2soaW5zdGFuY2UsIENvbnN0cnVjdG9yKSB7IGlmICghKGluc3RhbmNlIGluc3RhbmNlb2YgQ29uc3RydWN0b3IpKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJDYW5ub3QgY2FsbCBhIGNsYXNzIGFzIGEgZnVuY3Rpb25cIik7IH0gfVxuXG5mdW5jdGlvbiBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybihzZWxmLCBjYWxsKSB7IGlmICghc2VsZikgeyB0aHJvdyBuZXcgUmVmZXJlbmNlRXJyb3IoXCJ0aGlzIGhhc24ndCBiZWVuIGluaXRpYWxpc2VkIC0gc3VwZXIoKSBoYXNuJ3QgYmVlbiBjYWxsZWRcIik7IH0gcmV0dXJuIGNhbGwgJiYgKHR5cGVvZiBjYWxsID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBjYWxsID09PSBcImZ1bmN0aW9uXCIpID8gY2FsbCA6IHNlbGY7IH1cblxuZnVuY3Rpb24gX2luaGVyaXRzKHN1YkNsYXNzLCBzdXBlckNsYXNzKSB7IGlmICh0eXBlb2Ygc3VwZXJDbGFzcyAhPT0gXCJmdW5jdGlvblwiICYmIHN1cGVyQ2xhc3MgIT09IG51bGwpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIlN1cGVyIGV4cHJlc3Npb24gbXVzdCBlaXRoZXIgYmUgbnVsbCBvciBhIGZ1bmN0aW9uLCBub3QgXCIgKyB0eXBlb2Ygc3VwZXJDbGFzcyk7IH0gc3ViQ2xhc3MucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShzdXBlckNsYXNzICYmIHN1cGVyQ2xhc3MucHJvdG90eXBlLCB7IGNvbnN0cnVjdG9yOiB7IHZhbHVlOiBzdWJDbGFzcywgZW51bWVyYWJsZTogZmFsc2UsIHdyaXRhYmxlOiB0cnVlLCBjb25maWd1cmFibGU6IHRydWUgfSB9KTsgaWYgKHN1cGVyQ2xhc3MpIE9iamVjdC5zZXRQcm90b3R5cGVPZiA/IE9iamVjdC5zZXRQcm90b3R5cGVPZihzdWJDbGFzcywgc3VwZXJDbGFzcykgOiBzdWJDbGFzcy5fX3Byb3RvX18gPSBzdXBlckNsYXNzOyB9XG5cbnZhciBQcm9wVHlwZXMgPSByZXF1aXJlKCdwcm9wLXR5cGVzJyk7XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0JyksXG4gICAgZmx1eCA9IHJlcXVpcmUoJ2ZsdXhpZnknKTtcblxudmFyIEZvcm0gPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2Zvcm0vZm9ybS5qc3gnKSxcbiAgICBJbnB1dFRleHQgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2lucHV0LXRleHQvaW5wdXQtdGV4dC5qc3gnKSxcbiAgICBJbnB1dERhdGUgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2lucHV0LWRhdGUvaW5wdXQtZGF0ZS5qc3gnKSxcbiAgICBJbnB1dE51bWJlciA9IHJlcXVpcmUoJy4uLy4uL2NvbXBvbmVudHMvaW5wdXQtbnVtYmVyL2lucHV0LW51bWJlci5qc3gnKSxcbiAgICBEb2NDb21tb24gPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2RvYy1jb21tb24vZG9jLWNvbW1vbi5qc3gnKSxcbiAgICBTZWxlY3QgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL3NlbGVjdC9zZWxlY3QuanN4JyksXG5cbi8vICAgIFNlbGVjdERhdGEgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL3NlbGVjdC1kYXRhL3NlbGVjdC1kYXRhLmpzeCcpLFxuVGV4dEFyZWEgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL3RleHQtYXJlYS90ZXh0LWFyZWEuanN4JyksXG4gICAgRGF0YUdyaWQgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2RhdGEtZ3JpZC9kYXRhLWdyaWQuanN4JyksXG4gICAgR3JpZEJ1dHRvbkFkZCA9IHJlcXVpcmUoJy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi1yZWdpc3Rlci1hZGQvYnV0dG9uLXJlZ2lzdGVyLWFkZC5qc3gnKSxcbiAgICBHcmlkQnV0dG9uRWRpdCA9IHJlcXVpcmUoJy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi1yZWdpc3Rlci1lZGl0L2J1dHRvbi1yZWdpc3Rlci1lZGl0LmpzeCcpLFxuICAgIEdyaWRCdXR0b25EZWxldGUgPSByZXF1aXJlKCcuLi8uLi9jb21wb25lbnRzL2J1dHRvbi1yZWdpc3Rlci9idXR0b24tcmVnaXN0ZXItZGVsZXRlL2J1dHRvbi1yZWdpc3Rlci1kZWxldGUuanN4JyksXG4gICAgRG9rUHJvcCA9IHJlcXVpcmUoJy4uLy4uL2NvbXBvbmVudHMvZG9jcHJvcC9kb2Nwcm9wLmpzeCcpLFxuICAgIHJlbGF0ZWREb2N1bWVudHMgPSByZXF1aXJlKCcuLi8uLi9taXhpbi9yZWxhdGVkRG9jdW1lbnRzLmpzeCcpLFxuICAgIFRvb2xiYXJDb250YWluZXIgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvdG9vbGJhci1jb250YWluZXIvdG9vbGJhci1jb250YWluZXIuanN4JyksXG4gICAgTWVudVRvb2xCYXIgPSByZXF1aXJlKCcuLy4uLy4uL21peGluL21lbnVUb29sQmFyLmpzeCcpLFxuICAgIERvY1Rvb2xCYXIgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvZG9jLXRvb2xiYXIvZG9jLXRvb2xiYXIuanN4JyksXG4gICAgdmFsaWRhdGVGb3JtID0gcmVxdWlyZSgnLi4vLi4vbWl4aW4vdmFsaWRhdGVGb3JtJyksXG4gICAgTW9kYWxQYWdlID0gcmVxdWlyZSgnLi8uLi8uLi9jb21wb25lbnRzL21vZGFscGFnZS9tb2RhbFBhZ2UuanN4JyksXG4gICAgc3R5bGVzID0gcmVxdWlyZSgnLi9hcnZlLnN0eWxlcycpO1xuXG52YXIgTElCRE9LID0gJ0FSVicsXG4gICAgTElCUkFSSUVTID0gWydhc3V0dXNlZCcsICdrb250b2QnLCAnZG9rUHJvcHMnLCAndXNlcnMnLCAnYWEnLCAndHVubnVzJywgJ3Byb2plY3QnLCAnbm9tZW5jbGF0dXJlJ107XG5cbi8vIENyZWF0ZSBhIHN0b3JlXG52YXIgZG9jU3RvcmUgPSByZXF1aXJlKCcuLi8uLi9zdG9yZXMvZG9jX3N0b3JlLmpzJyk7XG5cbnZhciBub3cgPSBuZXcgRGF0ZSgpO1xuXG52YXIgQXJ2ZSA9IGZ1bmN0aW9uIChfUmVhY3QkUHVyZUNvbXBvbmVudCkge1xuICAgIF9pbmhlcml0cyhBcnZlLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBBcnZlKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBBcnZlKTtcblxuICAgICAgICB2YXIgX3RoaXMgPSBfcG9zc2libGVDb25zdHJ1Y3RvclJldHVybih0aGlzLCAoQXJ2ZS5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKEFydmUpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMuc3RhdGUgPSB7XG4gICAgICAgICAgICBlZGl0ZWQ6IF90aGlzLnByb3BzLmRhdGEucm93LmlkID09IDAsXG4gICAgICAgICAgICBzaG93TWVzc2FnZUJveDogJ25vbmUnLFxuICAgICAgICAgICAgcmVsYXRpb25zOiBfdGhpcy5wcm9wcy5kYXRhLnJlbGF0aW9ucyxcbiAgICAgICAgICAgIGdyaWRSb3dFZGl0OiBmYWxzZSxcbiAgICAgICAgICAgIGdyaWRSb3dFdmVudDogbnVsbCxcbiAgICAgICAgICAgIGNoZWNrZWQ6IGZhbHNlLFxuICAgICAgICAgICAgd2FybmluZzogJydcbiAgICAgICAgfTtcblxuICAgICAgICBfdGhpcy5kb2NEYXRhID0gX3RoaXMucHJvcHMuZGF0YS5yb3c7XG4gICAgICAgIF90aGlzLmdyaWREYXRhID0gX3RoaXMucHJvcHMuZGF0YS5kZXRhaWxzO1xuICAgICAgICBfdGhpcy5ncmlkQ29uZmlnID0gX3RoaXMucHJvcHMuZGF0YS5ncmlkQ29uZmlnO1xuICAgICAgICBfdGhpcy5ncmlkUm93RGF0YSA9IG51bGw7XG4gICAgICAgIF90aGlzLmxpYnMgPSBfdGhpcy5jcmVhdGVMaWJzKCk7XG5cbiAgICAgICAgX3RoaXMucGFnZXMgPSBbeyBwYWdlTmFtZTogJ0FydmUnIH1dO1xuICAgICAgICBfdGhpcy5yZXF1aXJlZEZpZWxkcyA9IFt7XG4gICAgICAgICAgICBuYW1lOiAna3B2JyxcbiAgICAgICAgICAgIHR5cGU6ICdEJyxcbiAgICAgICAgICAgIG1pbjogbm93LnNldEZ1bGxZZWFyKG5vdy5nZXRGdWxsWWVhcigpIC0gMSksXG4gICAgICAgICAgICBtYXg6IG5vdy5zZXRGdWxsWWVhcihub3cuZ2V0RnVsbFllYXIoKSArIDEpXG4gICAgICAgIH0sIHtcbiAgICAgICAgICAgIG5hbWU6ICd0YWh0YWVnJyxcbiAgICAgICAgICAgIHR5cGU6ICdEJyxcbiAgICAgICAgICAgIG1pbjogbm93LnNldEZ1bGxZZWFyKG5vdy5nZXRGdWxsWWVhcigpIC0gMSksXG4gICAgICAgICAgICBtYXg6IG5vdy5zZXRGdWxsWWVhcihub3cuZ2V0RnVsbFllYXIoKSArIDEpXG4gICAgICAgIH0sIHsgbmFtZTogJ2FzdXR1c2lkJywgdHlwZTogJ04nLCBtaW46IG51bGwsIG1heDogbnVsbCB9LCB7IG5hbWU6ICdzdW1tYScsIHR5cGU6ICdOJywgbWluOiAtOTk5OTk5OSwgbWF4OiA5OTk5OTkgfV07XG4gICAgICAgIF90aGlzLmhhbmRsZVRvb2xiYXJFdmVudHMgPSBfdGhpcy5oYW5kbGVUb29sYmFyRXZlbnRzLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy52YWxpZGF0aW9uID0gX3RoaXMudmFsaWRhdGlvbi5iaW5kKF90aGlzKTtcblxuICAgICAgICBfdGhpcy5tb2RhbFBhZ2VDbGljayA9IF90aGlzLm1vZGFsUGFnZUNsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2sgPSBfdGhpcy5oYW5kbGVHcmlkQnRuQ2xpY2suYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmFkZFJvdyA9IF90aGlzLmFkZFJvdy5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlR3JpZFJvd0NoYW5nZSA9IF90aGlzLmhhbmRsZUdyaWRSb3dDaGFuZ2UuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLnZhbGlkYXRlR3JpZFJvdyA9IF90aGlzLnZhbGlkYXRlR3JpZFJvdy5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlR3JpZFJvd0lucHV0ID0gX3RoaXMuaGFuZGxlR3JpZFJvd0lucHV0LmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5jcmVhdGVHcmlkUm93ID0gX3RoaXMuY3JlYXRlR3JpZFJvdy5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaGFuZGxlSW5wdXRDaGFuZ2UgPSBfdGhpcy5oYW5kbGVJbnB1dENoYW5nZS5iaW5kKF90aGlzKTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhBcnZlLCBbe1xuICAgICAgICBrZXk6ICdjb21wb25lbnREaWRNb3VudCcsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBjb21wb25lbnREaWRNb3VudCgpIHtcbiAgICAgICAgICAgIHZhciBfdGhpczIgPSB0aGlzO1xuXG4gICAgICAgICAgICBpZiAod2luZG93KSB7XG4gICAgICAgICAgICAgICAgd2luZG93LmFkZEV2ZW50TGlzdGVuZXIoJ2JlZm9yZXVubG9hZCcsIHRoaXMuY29tcG9uZW50Q2xlYW51cCk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIC8vINC/0LjRiNC10Lwg0LjRgdGF0L7QtNC90YvQtSDQtNCw0L3QvdGL0LUg0LIg0YXRgNCw0L3QuNC70LjRidC1LCDRgNC10LPQuNGB0YLRgNC40YDRg9C10Lwg0L7QsdGA0LDQsdC+0YLRh9C40LrQuCDRgdC+0LHRi9GC0LjQuVxuICAgICAgICAgICAgdmFyIHNlbGYgPSB0aGlzLFxuICAgICAgICAgICAgICAgIGRhdGEgPSBPYmplY3QuYXNzaWduKHt9LCBzZWxmLnByb3BzLmRhdGEucm93KSxcbiAgICAgICAgICAgICAgICBkZXRhaWxzID0gT2JqZWN0LmFzc2lnbihbXSwgc2VsZi5wcm9wcy5kYXRhLmRldGFpbHMpLFxuICAgICAgICAgICAgICAgIGdyaWRDb25maWcgPSBzZWxmLnByb3BzLmRhdGEuZ3JpZENvbmZpZztcblxuICAgICAgICAgICAgLy8g0YHQvtGF0YDQsNC90Y/QtdC8INC00LDQvdC90YvQtSDQsiDRhdGA0LDQvdC40LvQuNGJ0LVcbiAgICAgICAgICAgIGZsdXguZG9BY3Rpb24oJ2RhdGFDaGFuZ2UnLCBkYXRhKTtcbiAgICAgICAgICAgIGZsdXguZG9BY3Rpb24oJ2RvY0lkQ2hhbmdlJywgZGF0YS5pZCk7XG4gICAgICAgICAgICBmbHV4LmRvQWN0aW9uKCdkZXRhaWxzQ2hhbmdlJywgZGV0YWlscyk7IC8vINC00LDQvdC90YvQtSDQs9GA0LjQtNCwXG4gICAgICAgICAgICBmbHV4LmRvQWN0aW9uKCdncmlkQ29uZmlnQ2hhbmdlJywgZ3JpZENvbmZpZyk7IC8vINC00LDQvdC90YvQtSDQs9GA0LjQtNCwXG5cbiAgICAgICAgICAgIC8vINCz0YDRg9C30LjQvCDRgdC/0YDQsNCy0L7Rh9C90LjQutC4XG4gICAgICAgICAgICBMSUJSQVJJRVMuZm9yRWFjaChmdW5jdGlvbiAobGliKSB7XG4gICAgICAgICAgICAgICAgZmx1eC5kb0FjdGlvbihcImxvYWRMaWJzXCIsIGxpYik7XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgLy8g0LXRgdC70Lgg0L3QvtCy0YvQuSDQtNC+0LrRg9C80LXQvdGCIChpZCA9PSAwKVxuXG4gICAgICAgICAgICBpZiAoZGF0YS5pZCA9PSAwKSB7XG4gICAgICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignZWRpdGVkQ2hhbmdlJywgdHJ1ZSk7XG4gICAgICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignc2F2ZWRDaGFuZ2UnLCBmYWxzZSk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIC8vINC+0YLRgdC70LXQttC40LLQsNC10Lwg0YDQtdC20LjQvCDRgNC10LTQsNC60YLQuNGA0L7QstCw0L3QuNGPXG4gICAgICAgICAgICBkb2NTdG9yZS5vbignY2hhbmdlOmVkaXRlZCcsIGZ1bmN0aW9uIChuZXdWYWx1ZSwgcHJldmlvdXNWYWx1ZSkge1xuICAgICAgICAgICAgICAgIGlmIChuZXdWYWx1ZSAhPT0gcHJldmlvdXNWYWx1ZSkge1xuICAgICAgICAgICAgICAgICAgICBzZWxmLnNldFN0YXRlKHsgZWRpdGVkOiBuZXdWYWx1ZSB9KTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgZG9jU3RvcmUub24oJ2NoYW5nZTpsaWJzJywgZnVuY3Rpb24gKG5ld1ZhbHVlKSB7XG4gICAgICAgICAgICAgICAgdmFyIGlzQ2hhbmdlZCA9IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICBsaWJzRGF0YSA9IF90aGlzMi5saWJzO1xuXG4gICAgICAgICAgICAgICAgaWYgKG5ld1ZhbHVlLmxlbmd0aCA+IDApIHtcblxuICAgICAgICAgICAgICAgICAgICBuZXdWYWx1ZS5mb3JFYWNoKGZ1bmN0aW9uIChsaWIpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChsaWIuaWQgPT09ICdkb2tQcm9wcycpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAvLyDQvtGB0YLQsNCy0LjQvCDRgtC+0LvRjNC60L4g0LTQsNC90L3Ri9C1INGN0YLQvtCz0L4g0LTQvtC60YPQvNC10L3RgtCwXG5cbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChfdGhpczIubGlic1tsaWIuaWRdICYmIGxpYi5kYXRhLmxlbmd0aCA+IDApIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBsaWJzRGF0YVtsaWIuaWRdID0gbGliLmRhdGE7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgaXNDaGFuZ2VkID0gdHJ1ZTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAgICAgaWYgKGlzQ2hhbmdlZCkge1xuICAgICAgICAgICAgICAgICAgICBfdGhpczIubGlicyA9IGxpYnNEYXRhO1xuICAgICAgICAgICAgICAgICAgICBfdGhpczIuZm9yY2VVcGRhdGUoKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINGB0L3QuNC80LXRgiDQstGB0LUg0L/QvtC00L/QuNGB0LrQuFxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdjb21wb25lbnRDbGVhbnVwJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGNvbXBvbmVudENsZWFudXAoKSB7XG4gICAgICAgICAgICAvKlxyXG4gICAgICAgICAgICAgICAgICAgIGRvY1N0b3JlLm9mZignY2hhbmdlOmVkaXRlZCcpO1xyXG4gICAgICAgICAgICAgICAgICAgIGRvY1N0b3JlLm9mZignY2hhbmdlOmxpYnMnKTtcclxuICAgICAgICAgICAgKi9cbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnY29tcG9uZW50V2lsbFVubW91bnQnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gY29tcG9uZW50V2lsbFVubW91bnQoKSB7XG4gICAgICAgICAgICB0aGlzLmNvbXBvbmVudENsZWFudXAoKTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIC8vINGE0L7RgNC80LjRgNGD0LXQvCDQt9Cw0LLQuNGB0LjQvNC+0YHRgtC4XG4gICAgICAgICAgICByZWxhdGVkRG9jdW1lbnRzKHRoaXMpO1xuXG4gICAgICAgICAgICB2YXIgaXNFZGl0TW9kZSA9IHRoaXMuc3RhdGUuZWRpdGVkLFxuICAgICAgICAgICAgICAgIHZhbGlkYXRpb25NZXNzYWdlID0gdGhpcy52YWxpZGF0aW9uKCk7XG5cbiAgICAgICAgICAgIHZhciBidG5QYXJhbXMgPSB7XG4gICAgICAgICAgICAgICAgYnRuU3RhcnQ6IHtcbiAgICAgICAgICAgICAgICAgICAgc2hvdzogdHJ1ZVxuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH07XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgTWVudVRvb2xCYXIoYnRuUGFyYW1zLCB0aGlzLnByb3BzLnVzZXJEYXRhKSxcbiAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICBGb3JtLFxuICAgICAgICAgICAgICAgICAgICB7IHBhZ2VzOiB0aGlzLnBhZ2VzLFxuICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnZm9ybScsXG4gICAgICAgICAgICAgICAgICAgICAgICBoYW5kbGVQYWdlQ2xpY2s6IHRoaXMuaGFuZGxlUGFnZUNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGlzRWRpdE1vZGUgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgIFRvb2xiYXJDb250YWluZXIsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ3Rvb2xiYXItY29udGFpbmVyJyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IGNsYXNzTmFtZTogJ2RvYy10b29sYmFyLXdhcm5pbmcnIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsaWRhdGlvbk1lc3NhZ2UgPyBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnc3BhbicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbGlkYXRpb25NZXNzYWdlXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKSA6IG51bGxcbiAgICAgICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEb2NUb29sQmFyLCB7IGJwbTogdGhpcy5wcm9wcy5icG0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2RvYy10b29sYmFyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZWRpdGVkOiBpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkb2NTdGF0dXM6IHRoaXMuZG9jRGF0YS5kb2Nfc3RhdHVzLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWxpZGF0b3I6IHRoaXMudmFsaWRhdGlvbixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZXZlbnRIYW5kbGVyOiB0aGlzLmhhbmRsZVRvb2xiYXJFdmVudHMgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvYyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEb2NDb21tb24sIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnZG9jLWNvbW1vbicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHRoaXMuZG9jRGF0YSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgcmVmOiAnaW5wdXQtbnVtYmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpdGxlOiAnTnVtYmVyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdudW1iZXInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHRoaXMuZG9jRGF0YS5udW1iZXIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5oYW5kbGVJbnB1dENoYW5nZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dERhdGUsIHsgdGl0bGU6ICdLdXVwXFx4RTRldiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2twdicsIHZhbHVlOiB0aGlzLmRvY0RhdGEua3B2LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQta3B2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiB0aGlzLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0RGF0ZSwgeyB0aXRsZTogJ1RcXHhFNGh0YWVnICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAndGFodGFlZycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogdGhpcy5kb2NEYXRhLnRhaHRhZWcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC10YWh0YWVnJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiB0aGlzLmhhbmRsZUlucHV0Q2hhbmdlIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFNlbGVjdCwgeyB0aXRsZTogJ0FzdXR1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnYXN1dHVzaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbGliczogJ2FzdXR1c2VkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHRoaXMubGlic1snYXN1dHVzZWQnXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiB0aGlzLmRvY0RhdGEuYXN1dHVzaWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHRoaXMuZG9jRGF0YS5hc3V0dXMsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdzZWxlY3QtYXN1dHVzaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYnRuRGVsZXRlOiBpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHRoaXMuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXRUZXh0LCB7IHRpdGxlOiAnTGlzYSAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2xpc2EnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHRoaXMuZG9jRGF0YS5saXNhLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnaW5wdXQtbGlzYScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5oYW5kbGVJbnB1dENoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NDb2x1bW4gfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEb2tQcm9wLCB7IHRpdGxlOiAnS29udGVlcmltaW5lOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2Rva2xhdXNpZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBsaWJzOiAnZG9rUHJvcHMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHRoaXMuZG9jRGF0YS5kb2tsYXVzaWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZWZhdWx0VmFsdWU6IHRoaXMuZG9jRGF0YS5kb2twcm9wLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnZG9rcHJvcC1kb2tsYXVzaWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoVGV4dEFyZWEsIHsgdGl0bGU6ICdNXFx4RTRya3VzZWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnbXV1ZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3RleHRhcmVhLW11dWQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHRoaXMuZG9jRGF0YS5tdXVkIHx8ICcnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogIWlzRWRpdE1vZGUgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgICAgICBpc0VkaXRNb2RlID8gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgVG9vbGJhckNvbnRhaW5lcixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVmOiAnZ3JpZC10b29sYmFyLWNvbnRhaW5lcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwb3NpdGlvbjogJ2xlZnQnIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoR3JpZEJ1dHRvbkFkZCwgeyBvbkNsaWNrOiB0aGlzLmhhbmRsZUdyaWRCdG5DbGljaywgcmVmOiAnZ3JpZC1idXR0b24tYWRkJyB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChHcmlkQnV0dG9uRWRpdCwgeyBvbkNsaWNrOiB0aGlzLmhhbmRsZUdyaWRCdG5DbGljaywgcmVmOiAnZ3JpZC1idXR0b24tZWRpdCcgfSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoR3JpZEJ1dHRvbkRlbGV0ZSwgeyBvbkNsaWNrOiB0aGlzLmhhbmRsZUdyaWRCdG5DbGljaywgcmVmOiAnZ3JpZC1idXR0b24tZGVsZXRlJyB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgICAgICkgOiBudWxsLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChEYXRhR3JpZCwgeyBzb3VyY2U6ICdkZXRhaWxzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZERhdGE6IHRoaXMuZ3JpZERhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGdyaWRDb2x1bW5zOiB0aGlzLmdyaWRDb25maWcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZUdyaWRSb3c6IHRoaXMuaGFuZGxlR3JpZFJvdyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVhZE9ubHk6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdkYXRhLWdyaWQnIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dFRleHQsIHsgdGl0bGU6ICdTdW1tYSAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAnc3VtbWEnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdpbnB1dC1zdW1tYScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiB0aGlzLmRvY0RhdGEuc3VtbWEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5oYW5kbGVJbnB1dENoYW5nZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGF0dGVybjogJ15bMC05XSsoXFxcXC5bMC05XXsxLDR9KT8kJyB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0VGV4dCwgeyB0aXRsZTogJ0tcXHhFNGliZW1ha3MgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2tibScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2lucHV0LWtibScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogdGhpcy5kb2NEYXRhLmtibSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHRoaXMuaGFuZGxlSW5wdXRDaGFuZ2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhdHRlcm46ICdeWzAtOV0rKFxcXFwuWzAtOV17MSw0fSk/JCcgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgICAgICB0aGlzLnN0YXRlLmdyaWRSb3dFZGl0ID8gdGhpcy5jcmVhdGVHcmlkUm93KCkgOiBudWxsXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0LLQsNC70LjQtNCw0YbQuNGPINGE0L7RgNC80YtcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAndmFsaWRhdGlvbicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiB2YWxpZGF0aW9uKCkge1xuICAgICAgICAgICAgaWYgKCF0aGlzLnN0YXRlLmVkaXRlZCkgcmV0dXJuICcnO1xuXG4gICAgICAgICAgICB2YXIgcmVxdWlyZWRGaWVsZHMgPSB0aGlzLnJlcXVpcmVkRmllbGRzO1xuICAgICAgICAgICAgcmV0dXJuIHJlcXVpcmUoJy4uLy4uL21peGluL3ZhbGlkYXRlRm9ybScpKHRoaXMsIHJlcXVpcmVkRmllbGRzKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINC+0YLRgNCw0LHQvtGC0LDQtdC8IE9rINC40Lcg0LzQvtC00LDQu9GM0L3QvtCz0L4g0L7QutC90LBcclxuICAgICAgICAgKiBAcGFyYW0gYnRuRXZlbnRcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnbW9kYWxQYWdlQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gbW9kYWxQYWdlQ2xpY2soYnRuRXZlbnQpIHtcbiAgICAgICAgICAgIHZhciBfdGhpczMgPSB0aGlzO1xuXG4gICAgICAgICAgICBpZiAoYnRuRXZlbnQgPT0gJ09rJykge1xuXG4gICAgICAgICAgICAgICAgLy8g0LjRidC10Lwg0L/QviDQuNC0INGB0YLRgNC+0LrRgyDQsiDQtNCw0L3QvdGL0YUg0LPRgNC40LTQsCwg0LXRgdC70Lgg0L3QtdGCLCDRgtC+INC00L7QsdCw0LLQuNC8INGB0YLRgNC+0LrRg1xuICAgICAgICAgICAgICAgIGlmICghdGhpcy5ncmlkRGF0YS5zb21lKGZ1bmN0aW9uIChyb3cpIHtcbiAgICAgICAgICAgICAgICAgICAgaWYgKHJvdy5pZCA9PT0gX3RoaXMzLmdyaWRSb3dEYXRhLmlkKSByZXR1cm4gdHJ1ZTtcbiAgICAgICAgICAgICAgICB9KSkge1xuICAgICAgICAgICAgICAgICAgICAvLyDQstGB0YLQsNCy0LrQsCDQvdC+0LLQvtC5INGB0YLRgNC+0LrQuFxuICAgICAgICAgICAgICAgICAgICB0aGlzLmdyaWREYXRhLnNwbGljZSgwLCAwLCB0aGlzLmdyaWRSb3dEYXRhKTtcbiAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICB0aGlzLmdyaWREYXRhID0gdGhpcy5ncmlkRGF0YS5tYXAoZnVuY3Rpb24gKHJvdykge1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHJvdy5pZCA9PT0gX3RoaXMzLmdyaWRSb3dEYXRhLmlkKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgLy8g0L3QsNGI0LvQuCwg0LfQsNC80LXRidCw0LXQvFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBfdGhpczMuZ3JpZFJvd0RhdGE7XG4gICAgICAgICAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiByb3c7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgdGhpcy5yZWNhbGNEb2NTdW1tYSgpO1xuICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IGdyaWRSb3dFZGl0OiBmYWxzZSB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINCe0LHRgNCw0LHQvtGC0YfQuNC6INGB0L7QsdGL0YLQuNGPINC60LvQuNC6INC/0L4g0LLQutC70LDQtNC60LVcclxuICAgICAgICAgKiBAcGFyYW0gcGFnZVxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdoYW5kbGVQYWdlQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaGFuZGxlUGFnZUNsaWNrKHBhZ2UpIHtcbiAgICAgICAgICAgIGlmIChwYWdlLmRvY0lkKSB7XG4gICAgICAgICAgICAgICAgZG9jdW1lbnQubG9jYXRpb24uaHJlZiA9IFwiL2RvY3VtZW50L1wiICsgcGFnZS5kb2NUeXBlSWQgKyBwYWdlLmRvY0lkO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0LzQtdGC0L7QtCDQstGL0LfRi9Cy0LDQtdGC0YHRjyDQv9GA0Lgg0LLRi9Cx0L7RgNC1INC30LDQtNCw0YfQuFxyXG4gICAgICAgICAqIEBwYXJhbSBlXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVNlbGVjdFRhc2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaGFuZGxlU2VsZWN0VGFzayhlKSB7XG4gICAgICAgICAgICByZXR1cm4gZS50YXJnZXQudmFsdWU7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiAgdG9vbGJhciBldmVudCBoYW5kbGVyXHJcbiAgICAgICAgICogQHBhcmFtIGV2ZW50XHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZVRvb2xiYXJFdmVudHMnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaGFuZGxlVG9vbGJhckV2ZW50cyhldmVudCkge1xuICAgICAgICAgICAgc3dpdGNoIChldmVudCkge1xuICAgICAgICAgICAgICAgIGNhc2UgJ0NBTkNFTCc6XG4gICAgICAgICAgICAgICAgICAgIHRoaXMuZG9jRGF0YSA9IEpTT04ucGFyc2UoZmx1eC5zdG9yZXMuZG9jU3RvcmUuYmFja3VwLmRvY0RhdGEpOyAvLyDQstC+0YHRgdGC0LDQvdC+0LLQuNC8INC00LDQvdC90YvQtVxuICAgICAgICAgICAgICAgICAgICB0aGlzLmdyaWREYXRhID0gSlNPTi5wYXJzZShmbHV4LnN0b3Jlcy5kb2NTdG9yZS5iYWNrdXAuZ3JpZERhdGEpO1xuXG4gICAgICAgICAgICAgICAgICAgIGlmICh0aGlzLnN0YXRlLndhcm5pbmcgIT09ICcnKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICB0aGlzLnNldFN0YXRlKHsgd2FybmluZzogJycgfSk7XG4gICAgICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgICAgICB0aGlzLmZvcmNlVXBkYXRlKCk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgZGVmYXVsdDpcbiAgICAgICAgICAgICAgICAgICAgY29uc29sZS5lcnJvcignaGFuZGxlVG9vbGJhckV2ZW50cywgbm8gZXZlbnQgaGFuZGxlciBmb3IgJywgZXZlbnQpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0J7QsdGA0LDQsdC+0YLRh9C40Log0LjQt9C80LXQvdC10L3QuNC5INC40L3Qv9GD0YLQvtCyXHJcbiAgICAgICAgICogQHBhcmFtIGlucHV0TmFtZVxyXG4gICAgICAgICAqIEBwYXJhbSBpbnB1dFZhbHVlXHJcbiAgICAgICAgICogQHJldHVybnMge2Jvb2xlYW59XHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2hhbmRsZUlucHV0Q2hhbmdlJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZUlucHV0Q2hhbmdlKGlucHV0TmFtZSwgaW5wdXRWYWx1ZSkge1xuXG4gICAgICAgICAgICAvLyDQuNC30LzQtdC90LXQvdC40Y8g0LTQvtC/0YPRgdGC0LjQvNGLINGC0L7Qu9GM0LrQviDQsiDRgNC10LbQuNC80LUg0YDQtdC00LDQutGC0LjRgNC+0LLQsNC90LjRj1xuICAgICAgICAgICAgaWYgKCF0aGlzLnN0YXRlLmVkaXRlZCkge1xuICAgICAgICAgICAgICAgIGNvbnNvbGUuZXJyb3IoJ25vdCBpbiBlZGl0ZSBtb2RlJyk7XG4gICAgICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICB0aGlzLmRvY0RhdGFbaW5wdXROYW1lXSA9IGlucHV0VmFsdWU7XG4gICAgICAgICAgICB0aGlzLmZvcmNlVXBkYXRlKCk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQn9C+0LTQs9C+0YLQvtCy0LrQsCDQv9Cw0YDQsNC80LXRgtGA0L7QsiDQtNC70Y8g0L/QsNC90LXQu9C4INC40L3RgdGC0YDRg9C80LXQvdGC0L7QslxyXG4gICAgICAgICAqIEBwYXJhbSBpc0VkaXRNb2RlXHJcbiAgICAgICAgICogQHJldHVybnMge3tidG5BZGQ6IHtzaG93OiBib29sZWFuLCBkaXNhYmxlZDogKn0sIGJ0bkVkaXQ6IHtzaG93OiBib29sZWFuLCBkaXNhYmxlZDogKn0sIGJ0blByaW50OiB7c2hvdzogYm9vbGVhbiwgZGlzYWJsZWQ6IGJvb2xlYW59LCBidG5TYXZlOiB7c2hvdzogKiwgZGlzYWJsZWQ6IGJvb2xlYW59fX1cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncHJlcGFpcmVUb29sQmFyUGFyYW1ldGVycycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBwcmVwYWlyZVRvb2xCYXJQYXJhbWV0ZXJzKGlzRWRpdE1vZGUpIHtcbiAgICAgICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICAgICAgYnRuQWRkOiB7XG4gICAgICAgICAgICAgICAgICAgIHNob3c6ICFpc0VkaXRNb2RlLFxuICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogaXNFZGl0TW9kZVxuICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgYnRuRWRpdDoge1xuICAgICAgICAgICAgICAgICAgICBzaG93OiAhaXNFZGl0TW9kZSxcbiAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGlzRWRpdE1vZGVcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIGJ0blByaW50OiB7XG4gICAgICAgICAgICAgICAgICAgIHNob3c6IHRydWUsXG4gICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBidG5TYXZlOiB7XG4gICAgICAgICAgICAgICAgICAgIHNob3c6IGlzRWRpdE1vZGUsXG4gICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiBmYWxzZVxuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH07XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQvtCx0YDQsNCx0L7RgtGH0LjQuiDQtNC70Y8g0YHQvtCx0YvRgtC40Lkg0LrQu9C40Log0L/QsNC90LXQu9C4INC40L3RgdGC0YDRg9C80LXQvdGC0L7QsiDQs9GA0LjQtNCwXHJcbiAgICAgICAgICogQHBhcmFtIGJ0bk5hbWVcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnaGFuZGxlR3JpZEJ0bkNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZUdyaWRCdG5DbGljayhidG5OYW1lKSB7XG4gICAgICAgICAgICBzd2l0Y2ggKGJ0bk5hbWUpIHtcbiAgICAgICAgICAgICAgICBjYXNlICdhZGQnOlxuICAgICAgICAgICAgICAgICAgICB0aGlzLmFkZFJvdygpO1xuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICBjYXNlICdlZGl0JzpcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5lZGl0Um93KCk7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIGNhc2UgJ2RlbGV0ZSc6XG4gICAgICAgICAgICAgICAgICAgIHRoaXMuZGVsZXRlUm93KCk7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0YPQtNCw0LvQuNGCINCw0LrRgtC40LLQvdGD0Y4g0YHRgtGA0L7QutGDXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2RlbGV0ZVJvdycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBkZWxldGVSb3coKSB7XG4gICAgICAgICAgICB2YXIgZ3JpZEFjdGl2ZVJvdyA9IHRoaXMucmVmc1snZGF0YS1ncmlkJ10uc3RhdGUuYWN0aXZlUm93O1xuXG4gICAgICAgICAgICB0aGlzLmdyaWREYXRhLnNwbGljZShncmlkQWN0aXZlUm93LCAxKTtcblxuICAgICAgICAgICAgLy8g0L/QtdGA0LXRgNCw0YHRh9C10YIg0LjRgtC+0LPQvtCyXG4gICAgICAgICAgICB0aGlzLnJlY2FsY0RvY1N1bW1hKCk7XG5cbiAgICAgICAgICAgIC8vINC40LfQvNC10L3QuNC8INGB0L7RgdGC0L7Rj9C90LjQtVxuICAgICAgICAgICAgdGhpcy5mb3JjZVVwZGF0ZSgpO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0L7RgtC60YDQvtC10YIg0LDQutGC0LjQstC90YPRjiDRgdGC0YDQvtC60YMg0LTQu9GPINGA0LXQtNCw0LrRgtC40YDQvtCy0LDQvdC40Y9cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnZWRpdFJvdycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBlZGl0Um93KCkge1xuICAgICAgICAgICAgdGhpcy5ncmlkUm93RGF0YSA9IHRoaXMuZ3JpZERhdGFbdGhpcy5yZWZzWydkYXRhLWdyaWQnXS5zdGF0ZS5hY3RpdmVSb3ddO1xuXG4gICAgICAgICAgICAvLyDQvtGC0LrRgNC+0LXQvCDQvNC+0LTQsNC70YzQvdC+0LUg0L7QutC90L4g0LTQu9GPINGA0LXQtNCw0LrRgtC40YDQvtCy0LDQvdC40Y9cbiAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyBncmlkUm93RWRpdDogdHJ1ZSwgZ3JpZFJvd0V2ZW50OiAnZWRpdCcgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQtNC+0LHQsNCy0LjRgiDQsiDRgdC+0YHRgtC+0Y/QvdC40LUg0L3QvtCy0YPRjiDRgdGC0YDQvtC60YNcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnYWRkUm93JyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGFkZFJvdygpIHtcbiAgICAgICAgICAgIHZhciBuZXdSb3cgPSB7fTtcblxuICAgICAgICAgICAgZm9yICh2YXIgaSA9IDA7IGkgPCB0aGlzLmdyaWRDb25maWcubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICAgICAgICB2YXIgZmllbGQgPSB0aGlzLmdyaWRDb25maWdbaV0uaWQ7XG4gICAgICAgICAgICAgICAgbmV3Um93W2ZpZWxkXSA9ICcnO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBuZXdSb3cuaWQgPSAnTkVXJyArIE1hdGgucmFuZG9tKCk7IC8vINCz0LXQvdC10YDQuNC8INC90L7QstC+0LUg0LjQtFxuXG4gICAgICAgICAgICB0aGlzLmdyaWRSb3dEYXRhID0gbmV3Um93O1xuICAgICAgICAgICAgLy8g0L7RgtC60YDQvtC10Lwg0LzQvtC00LDQu9GM0L3QvtC1INC+0LrQvdC+INC00LvRjyDRgNC10LTQsNC60YLQuNGA0L7QstCw0L3QuNGPXG4gICAgICAgICAgICB0aGlzLnNldFN0YXRlKHsgZ3JpZFJvd0VkaXQ6IHRydWUsIGdyaWRSb3dFdmVudDogJ2FkZCcgfSk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQodC+0LfQtNCw0YHRgiDQutC+0LzQv9C+0L3QtdGCINGB0YLRgNC+0LrQuCDQs9GA0LjQtNCwXHJcbiAgICAgICAgICogQHJldHVybnMge1hNTH1cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnY3JlYXRlR3JpZFJvdycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBjcmVhdGVHcmlkUm93KCkge1xuICAgICAgICAgICAgdmFyIHZhbGlkYXRlTWVzc2FnZSA9ICcnLFxuICAgICAgICAgICAgICAgIG1vZGFsT2JqZWN0cyA9IFsnYnRuT2snLCAnYnRuQ2FuY2VsJ10sXG4gICAgICAgICAgICAgICAgYnV0dG9uT2tSZWFkT25seSA9IHZhbGlkYXRlTWVzc2FnZS5sZW5ndGggPiAwIHx8ICF0aGlzLnN0YXRlLmNoZWNrZWQ7XG5cbiAgICAgICAgICAgIGlmIChidXR0b25Pa1JlYWRPbmx5KSB7XG4gICAgICAgICAgICAgICAgLy8g0YPQsdC10YDQtdC8INC60L3QvtC/0LrRgyDQntC6XG4gICAgICAgICAgICAgICAgbW9kYWxPYmplY3RzLnNwbGljZSgwLCAxKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgaWYgKCF0aGlzLmdyaWRSb3dEYXRhKSByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudCgnZGl2JywgbnVsbCk7XG5cbiAgICAgICAgICAgIHZhciBub21EYXRhID0gdGhpcy5saWJzWydub21lbmNsYXR1cmUnXS5maWx0ZXIoZnVuY3Rpb24gKGxpYikge1xuICAgICAgICAgICAgICAgIGlmICghbGliLmRvayB8fCBsaWIuZG9rID09PSBMSUJET0spIHJldHVybiBsaWI7XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgeyBjbGFzc05hbWU6ICcubW9kYWxQYWdlJyB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgIE1vZGFsUGFnZSxcbiAgICAgICAgICAgICAgICAgICAge1xuICAgICAgICAgICAgICAgICAgICAgICAgbW9kYWxPYmplY3RzOiBtb2RhbE9iamVjdHMsXG4gICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdtb2RhbHBhZ2UtZ3JpZC1yb3cnLFxuICAgICAgICAgICAgICAgICAgICAgICAgc2hvdzogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIG1vZGFsUGFnZUJ0bkNsaWNrOiB0aGlzLm1vZGFsUGFnZUNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgbW9kYWxQYWdlTmFtZTogJ1JlYSBsaXNhbWluZSAvIHBhcmFuZGFtaW5lJyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ2dyaWQtcm93LWNvbnRhaW5lcicgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoU2VsZWN0LCB7IHRpdGxlOiAnVGVlbnVzJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ25vbWlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbGliczogJ25vbWVuY2xhdHVyZScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IG5vbURhdGEsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHRoaXMuZ3JpZFJvd0RhdGEubm9taWQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlZmF1bHRWYWx1ZTogdGhpcy5ncmlkUm93RGF0YS5rb29kLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdub21pZCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBsYWNlaG9sZGVyOiAnVGVlbnVzZSBrb29kJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHRoaXMuaGFuZGxlR3JpZFJvd0NoYW5nZSB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgdGl0bGU6ICdLb2d1cyAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiAna29ndXMnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHRoaXMuZ3JpZFJvd0RhdGEua29ndXMpLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWFkT25seTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYmluZERhdGE6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdrb2d1cycsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNsYXNzTmFtZTogJ3VpLWMyJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2U6IHRoaXMuaGFuZGxlR3JpZFJvd0lucHV0IH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dE51bWJlciwgeyB0aXRsZTogJ0hpbmQgJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2hpbmQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogTnVtYmVyKHRoaXMuZ3JpZFJvd0RhdGEuaGluZCksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlYWRPbmx5OiBmYWxzZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBiaW5kRGF0YTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2hpbmQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjbGFzc05hbWU6ICd1aS1jMicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2hhbmdlOiB0aGlzLmhhbmRsZUdyaWRSb3dJbnB1dCB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBzdHlsZTogc3R5bGVzLmRvY1JvdyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoSW5wdXROdW1iZXIsIHsgdGl0bGU6ICdLYm0tdGE6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdrYm10YScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIodGhpcy5ncmlkUm93RGF0YS5rYm10YSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBiaW5kRGF0YTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ2tibXRhJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY2xhc3NOYW1lOiAndWktYzInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5oYW5kbGVHcmlkUm93Q2hhbmdlIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuZG9jUm93IH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChJbnB1dE51bWJlciwgeyB0aXRsZTogJ0tibTogJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2tibScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIodGhpcy5ncmlkUm93RGF0YS5rYm0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYmluZERhdGE6IGZhbHNlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWY6ICdrYm0nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjbGFzc05hbWU6ICd1aS1jMicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQmx1cjogdGhpcy5oYW5kbGVHcmlkUm93SW5wdXQgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgICksXG4gICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgc3R5bGU6IHN0eWxlcy5kb2NSb3cgfSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KElucHV0TnVtYmVyLCB7IHRpdGxlOiAnU3VtbWE6ICcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG5hbWU6ICdTdW1tYScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBOdW1iZXIodGhpcy5ncmlkUm93RGF0YS5zdW1tYSksXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGVkOiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBiaW5kRGF0YTogZmFsc2UsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3N1bW1hJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY2xhc3NOYW1lOiAndWktYzInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZTogdGhpcy5oYW5kbGVHcmlkUm93SW5wdXQgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICAgICAgKSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJ3NwYW4nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG51bGwsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsaWRhdGVNZXNzYWdlXG4gICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0L7RgtGB0LvQtdC20LjQstCw0LXQvCDQuNC30LzQtdC90LXQvdC40Y8g0LTQsNC90L3Ri9GFINC90LAg0YTQvtGA0LxcclxuICAgICAgICAgKiBAcGFyYW0gbmFtZVxyXG4gICAgICAgICAqIEBwYXJhbSB2YWx1ZVxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdoYW5kbGVHcmlkUm93Q2hhbmdlJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZUdyaWRSb3dDaGFuZ2UobmFtZSwgdmFsdWUpIHtcbiAgICAgICAgICAgIHZhciBfdGhpczQgPSB0aGlzO1xuXG4gICAgICAgICAgICBpZiAodmFsdWUgIT09IHRoaXMuZ3JpZFJvd0RhdGFbbmFtZV0gJiYgbmFtZSA9PT0gJ25vbWlkJykge1xuICAgICAgICAgICAgICAgIC8vINC/0YDQvtC40LfQvtGI0LvQviDQuNC30LzQtdC90LXQvdC40LUg0YPRgdC70YPQs9C4LCDQvtCx0L3Rg9C70LjQvCDQt9C90LDRh9C10L3QuNGPXG4gICAgICAgICAgICAgICAgdGhpcy5ncmlkUm93RGF0YVsna29ndXMnXSA9IDA7XG4gICAgICAgICAgICAgICAgdGhpcy5ncmlkUm93RGF0YVsnaGluZCddID0gMDtcbiAgICAgICAgICAgICAgICB0aGlzLmdyaWRSb3dEYXRhWydzdW1tYSddID0gMDtcbiAgICAgICAgICAgICAgICB0aGlzLmdyaWRSb3dEYXRhWydrYm0nXSA9IDA7XG4gICAgICAgICAgICAgICAgdGhpcy5ncmlkUm93RGF0YVsna2JtdGEnXSA9IDA7XG4gICAgICAgICAgICAgICAgdGhpcy5ncmlkUm93RGF0YVsnbm9taWQnXSA9IHZhbHVlO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgLy8g0LjRidC10Lwg0L/QviDRgdC/0YDQsNCy0L7Rh9C90LjQutGDINC/0L7Qu9GPINC60L7QtCDQuCDQvdCw0LjQvNC10L3QvtCy0LDQvdC40LVcblxuICAgICAgICAgICAgdmFyIGxpYkRhdGEgPSB0aGlzLmxpYnNbJ25vbWVuY2xhdHVyZSddO1xuICAgICAgICAgICAgbGliRGF0YS5mb3JFYWNoKGZ1bmN0aW9uIChyb3cpIHtcbiAgICAgICAgICAgICAgICBpZiAocm93LmlkID09IHZhbHVlKSB7XG4gICAgICAgICAgICAgICAgICAgIF90aGlzNC5ncmlkUm93RGF0YVsna29vZCddID0gcm93Lmtvb2Q7XG4gICAgICAgICAgICAgICAgICAgIF90aGlzNC5ncmlkUm93RGF0YVsnbmltZXR1cyddID0gcm93Lm5hbWU7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgIHRoaXMuZ3JpZFJvd0RhdGFbbmFtZV0gPSB2YWx1ZTtcbiAgICAgICAgICAgIC8vICAgICAgICB0aGlzLmZvcmNlVXBkYXRlKCk7XG4gICAgICAgICAgICB0aGlzLnZhbGlkYXRlR3JpZFJvdygpO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0J7QsdGA0LDQsdC+0YLRh9C40Log0LTQu9GPINGB0YLRgNC+0LrQuCDQs9GA0LjQtNCwXHJcbiAgICAgICAgICogQHBhcmFtIG5hbWVcclxuICAgICAgICAgKiBAcGFyYW0gdmFsdWVcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnaGFuZGxlR3JpZFJvd0lucHV0JyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGhhbmRsZUdyaWRSb3dJbnB1dChuYW1lLCB2YWx1ZSkge1xuICAgICAgICAgICAgdGhpcy5ncmlkUm93RGF0YVtuYW1lXSA9IHZhbHVlO1xuXG4gICAgICAgICAgICAvLyDQv9C10YDQtdGB0YfQtdGCINGB0YPQvNC8XG4gICAgICAgICAgICB0aGlzLnJlY2FsY1Jvd1N1bW0oKTtcbiAgICAgICAgICAgIC8vICAgICAgICB0aGlzLmZvcmNlVXBkYXRlKCk7XG4gICAgICAgICAgICB0aGlzLnZhbGlkYXRlR3JpZFJvdygpO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0L/QtdGA0LXRgNCw0YHRh9C10YIg0YHRg9C80LzRiyDRgdGC0YDQvtC60Lgg0Lgg0YDQsNGB0YfQtdGCINC90LDQu9C+0LPQsFxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZWNhbGNSb3dTdW1tJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlY2FsY1Jvd1N1bW0oKSB7XG4gICAgICAgICAgICB0aGlzLmdyaWRSb3dEYXRhWydrb2d1cyddID0gTnVtYmVyKHRoaXMuZ3JpZFJvd0RhdGEua29ndXMpO1xuICAgICAgICAgICAgdGhpcy5ncmlkUm93RGF0YVsnaGluZCddID0gTnVtYmVyKHRoaXMuZ3JpZFJvd0RhdGEuaGluZCk7XG4gICAgICAgICAgICB0aGlzLmdyaWRSb3dEYXRhWydrYm10YSddID0gTnVtYmVyKHRoaXMuZ3JpZFJvd0RhdGFbJ2tvZ3VzJ10pICogTnVtYmVyKHRoaXMuZ3JpZFJvd0RhdGFbJ2hpbmQnXSk7XG4gICAgICAgICAgICB0aGlzLmdyaWRSb3dEYXRhWydrYm0nXSA9IE51bWJlcih0aGlzLmdyaWRSb3dEYXRhWydrYm10YSddICogMC4yMCk7IC8vIEB0b2RvINCy0YDQvNC10L3QvdC+XG4gICAgICAgICAgICB0aGlzLmdyaWRSb3dEYXRhWydzdW1tYSddID0gTnVtYmVyKHRoaXMuZ3JpZFJvd0RhdGFbJ2tibXRhJ10pICsgTnVtYmVyKHRoaXMuZ3JpZFJvd0RhdGFbJ2tibSddKTtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINCf0LXRgNC10YDQsNGB0YfQtdGCINC40YLQvtCz0L7QstGL0YUg0YHRg9C80Lwg0LTQvtC60YPQvNC10L3RgtCwXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlY2FsY0RvY1N1bW1hJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlY2FsY0RvY1N1bW1hKCkge1xuICAgICAgICAgICAgdmFyIF90aGlzNSA9IHRoaXM7XG5cbiAgICAgICAgICAgIHRoaXMuZG9jRGF0YVsnc3VtbWEnXSA9IDA7XG4gICAgICAgICAgICB0aGlzLmRvY0RhdGFbJ2tibSddID0gMDtcbiAgICAgICAgICAgIHRoaXMuZ3JpZERhdGEuZm9yRWFjaChmdW5jdGlvbiAocm93KSB7XG4gICAgICAgICAgICAgICAgX3RoaXM1LmRvY0RhdGFbJ3N1bW1hJ10gKz0gTnVtYmVyKHJvd1snc3VtbWEnXSk7XG4gICAgICAgICAgICAgICAgX3RoaXM1LmRvY0RhdGFbJ2tibSddICs9IE51bWJlcihyb3dbJ2tibSddKTtcbiAgICAgICAgICAgIH0pO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICogd2lsbCBjaGVjayB2YWx1ZXMgb24gdGhlIGZvcm0gYW5kIHJldHVybiBzdHJpbmcgd2l0aCB3YXJuaW5nXHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3ZhbGlkYXRlR3JpZFJvdycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiB2YWxpZGF0ZUdyaWRSb3coKSB7XG4gICAgICAgICAgICB2YXIgd2FybmluZyA9ICcnO1xuXG4gICAgICAgICAgICAvLyDRgtC+0LvRjNC60L4g0L/QvtGB0LvQtSDQv9GA0L7QstC10YDQutC4INGE0L7RgNC80Ysg0L3QsCDQstCw0LvQuNC00L3QvtGB0YLRjFxuICAgICAgICAgICAgaWYgKCF0aGlzLmdyaWRSb3dEYXRhWydub21pZCddKSB3YXJuaW5nID0gd2FybmluZyArICcg0LrQvtC0INGD0YHQu9GD0LPQuCc7XG4gICAgICAgICAgICBpZiAoIXRoaXMuZ3JpZFJvd0RhdGFbJ2tvZ3VzJ10pIHdhcm5pbmcgPSB3YXJuaW5nICsgJyDQutC+0Lst0LLQvic7XG4gICAgICAgICAgICBpZiAoIXRoaXMuZ3JpZFJvd0RhdGFbJ2hpbmQnXSkgd2FybmluZyA9IHdhcm5pbmcgKyAnINGG0LXQvdCwJztcblxuICAgICAgICAgICAgaWYgKHdhcm5pbmcubGVuZ3RoID4gMikge1xuICAgICAgICAgICAgICAgIC8vINC10YHRgtGMINC/0YDQvtCx0LvQtdC80YtcbiAgICAgICAgICAgICAgICB3YXJuaW5nID0gJ9Ce0YLRgdGD0YLRgdCy0YPRjtGCINC00LDQvdC90YvQtTonICsgd2FybmluZztcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyBjaGVja2VkOiB0cnVlLCB3YXJuaW5nOiB3YXJuaW5nIH0pO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0LLQtdGA0L3QtdGCINC+0LHRitC10LrRgiDQsdC40LHQu9C40L7RgtC10Log0LTQvtC60YPQvNC10L3RgtCwXHJcbiAgICAgICAgICogQHJldHVybnMge3t9fVxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdjcmVhdGVMaWJzJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGNyZWF0ZUxpYnMoKSB7XG4gICAgICAgICAgICB2YXIgbGlicyA9IHt9O1xuICAgICAgICAgICAgTElCUkFSSUVTLmZvckVhY2goZnVuY3Rpb24gKGxpYikge1xuICAgICAgICAgICAgICAgIGxpYnNbbGliXSA9IFtdO1xuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICByZXR1cm4gbGlicztcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBBcnZlO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuQXJ2ZS5wcm9wVHlwZXMgPSB7XG4gICAgZGF0YTogUHJvcFR5cGVzLm9iamVjdC5pc1JlcXVpcmVkLFxuICAgIGJwbTogUHJvcFR5cGVzLmFycmF5LFxuICAgIGVkaXRlZDogUHJvcFR5cGVzLmJvb2wsXG4gICAgc2hvd01lc3NhZ2VCb3g6IFByb3BUeXBlcy5zdHJpbmcsXG4gICAgZ3JpZERhdGE6IFByb3BUeXBlcy5hcnJheSxcbiAgICByZWxhdGlvbnM6IFByb3BUeXBlcy5hcnJheSxcbiAgICBncmlkQ29uZmlnOiBQcm9wVHlwZXMuYXJyYXksXG4gICAgZ3JpZFJvd0VkaXQ6IFByb3BUeXBlcy5ib29sLFxuICAgIGdyaWRSb3dFdmVudDogUHJvcFR5cGVzLnN0cmluZyxcbiAgICBncmlkUm93RGF0YTogUHJvcFR5cGVzLm9iamVjdCxcbiAgICBsaWJzOiBQcm9wVHlwZXMub2JqZWN0LFxuICAgIGNoZWNrZWQ6IFByb3BUeXBlcy5ib29sLFxuICAgIHdhcm5pbmc6IFByb3BUeXBlcy5zdHJpbmdcblxufTtcblxuLypcclxuIEFydmUuZGVmYXVsdFByb3BzID0ge1xyXG4gZGlzYWJsZWQ6IGZhbHNlLFxyXG4gc2hvdzogdHJ1ZVxyXG4gfTtcclxuICovXG5cbm1vZHVsZS5leHBvcnRzID0gQXJ2ZTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MvYXJ2ZS9hcnZlLmpzeFxuLy8gbW9kdWxlIGlkID0gMlxuLy8gbW9kdWxlIGNodW5rcyA9IDAgNCIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgICAgIGRvY1Jvdzoge1xuICAgICAgICAgICAgICAgIGRpc3BsYXk6ICdmbGV4JyxcbiAgICAgICAgICAgICAgICBmbGV4RGlyZWN0aW9uOiAncm93J1xuICAgICAgICAgICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBibHVlJ1xyXG4gICAgICAgICAgICAgICAgKi9cbiAgICAgICAgfSxcbiAgICAgICAgZG9jQ29sdW1uOiB7XG4gICAgICAgICAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICAgICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nLFxuICAgICAgICAgICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCB5ZWxsb3cnLFxyXG4gICAgICAgICAgICAgICAgKi9cbiAgICAgICAgICAgICAgICB3aWR0aDogJzUwJSdcbiAgICAgICAgfSxcbiAgICAgICAgZG9jOiB7XG4gICAgICAgICAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICAgICAgICAgIGZsZXhEaXJlY3Rpb246ICdjb2x1bW4nXG4gICAgICAgICAgICAgICAgLypcclxuICAgICAgICAgICAgICAgICAgICAgICAgYm9yZGVyOiAnMXB4IHNvbGlkIGJyb3duJ1xyXG4gICAgICAgICAgICAgICAgKi9cbiAgICAgICAgfSxcbiAgICAgICAgZ3JpZFJvdzoge1xuICAgICAgICAgICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGJvcmRlcjogJzFweCBzb2xpZCBibGFjaycsXHJcbiAgICAgICAgICAgICAgICAqL1xuICAgICAgICAgICAgICAgIGJhY2tncm91bmRDb2xvcjogJ3doaXRlJyxcbiAgICAgICAgICAgICAgICBwb3NpdGlvbjogJ3JlbGF0aXZlJyxcbiAgICAgICAgICAgICAgICBtYXJnaW46ICcxMCUgMzAlIDEwJSAzMCUnLFxuICAgICAgICAgICAgICAgIHdpZHRoOiAnYXV0bycsXG4gICAgICAgICAgICAgICAgb3BhY2l0eTogJzEnLFxuICAgICAgICAgICAgICAgIHRvcDogJzEwMHB4J1xuICAgICAgICB9XG5cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9kb2NzL2FydmUvYXJ2ZS5zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDEyOFxuLy8gbW9kdWxlIGNodW5rcyA9IDAgNCIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbiAoZG9jVHlwZUlkKSB7XG4gICAgLy8g0LLQt9Cw0LLQuNGB0LjQvNC+0YHRgtC4INC+0YIg0YLQuNC/0LAg0LTQvtC60YPQvNC10L3RgtCwINCy0LXRgNC90LXRgiDQutC+0LzQv9C+0L3QtdC90YIg0LTQvtC60YPQvNC10L3RgtCwXG5cbiAgICBjb25zb2xlLmxvZygncmV0dXJuRG9jQ29tcG9uZW50OicgKyBkb2NUeXBlSWQpO1xuICAgIHZhciBjb21wb25lbnQgPSB7fTtcblxuICAgIHN3aXRjaCAoZG9jVHlwZUlkKSB7XG4gICAgICAgIGNhc2UgJ1BBTEsnOlxuICAgICAgICAgICAgY29tcG9uZW50ID0gcmVxdWlyZSgnLi4vZnJvbnRlbmQvZG9jcy9wYWxrX29wZXIuanN4Jyk7XG4gICAgICAgICAgICBicmVhaztcbiAgICAgICAgZGVmYXVsdDpcbiAgICAgICAgICAgIGNvbXBvbmVudCA9IHJlcXVpcmUoJy4uL2Zyb250ZW5kL2RvY3MvYXJ2ZS9hcnZlLmpzeCcpO1xuICAgIH1cbiAgICByZXR1cm4gY29tcG9uZW50O1xufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL21pZGRsZXdhcmUvcmV0dXJuRG9jQ29tcG9uZW50LmpzXG4vLyBtb2R1bGUgaWQgPSAxNzJcbi8vIG1vZHVsZSBjaHVua3MgPSA0IiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xudmFyIEZvcm0gPSByZXF1aXJlKCcuLi9jb21wb25lbnRzL2Zvcm0uanMnKTtcbnZhciBQYWdlTGFiZWwgPSByZXF1aXJlKCcuLi9jb21wb25lbnRzL3BhZ2VfbGFiZWwnKTtcblxudmFyIHBhZ2VzID0gWydQYWdlMScsICdQYWdlMiddO1xuXG52YXIgUGFsayA9IFJlYWN0LmNyZWF0ZUNsYXNzKHtcbiAgICBkaXNwbGF5TmFtZTogJ1BhbGsnLFxuXG4gICAgcmVuZGVyOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgRm9ybSxcbiAgICAgICAgICAgIHsgcGFnZXM6IHBhZ2VzIH0sXG4gICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICdzcGFuJyxcbiAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICcgUGFsayAnXG4gICAgICAgICAgICApXG4gICAgICAgICk7XG4gICAgfSB9KTtcblxubW9kdWxlLmV4cG9ydHMgPSBQYWxrO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9wYWxrX29wZXIuanN4XG4vLyBtb2R1bGUgaWQgPSAxNzNcbi8vIG1vZHVsZSBjaHVua3MgPSA0IiwiJ3VzZSBzdHJpY3QnO1xuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpLFxuICAgIGZsdXggPSByZXF1aXJlKCdmbHV4aWZ5Jyk7XG5cbnZhciBQYWdlTGFiZWwgPSByZXF1aXJlKCcuL3BhZ2VfbGFiZWwnKTtcblxudmFyIEZvcm0gPSBSZWFjdC5jcmVhdGVDbGFzcyh7XG4gICAgZGlzcGxheU5hbWU6ICdGb3JtJyxcblxuICAgIGdldEluaXRpYWxTdGF0ZTogZnVuY3Rpb24gZ2V0SW5pdGlhbFN0YXRlKCkge1xuICAgICAgICB2YXIgcGFnZXMgPSBbeyBwYWdlTmFtZTogJ1BhZ2UnIH1dO1xuICAgICAgICBpZiAodGhpcy5wcm9wcy5wYWdlcykge1xuICAgICAgICAgICAgcGFnZXMgPSB0aGlzLnByb3BzLnBhZ2VzO1xuICAgICAgICB9XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBwYWdlczogdGhpcy5wcm9wcy5wYWdlc1xuICAgICAgICB9O1xuICAgIH0sXG5cbiAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgdmFyIHBhZ2VzID0gdGhpcy5zdGF0ZS5wYWdlcztcbiAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoJ2RpdicsIHsgY2xhc3NOYW1lOiAnY29udGFpbmVyJyB9LCBwYWdlcy5tYXAoZnVuY3Rpb24gKHBhZ2UsIGlkeCkge1xuICAgICAgICAgICAgcmV0dXJuIFJlYWN0LmNyZWF0ZUVsZW1lbnQoUGFnZUxhYmVsLCB7IGtleTogaWR4LCBwYWdlSWR4OiBpZHggfSwgcGFnZSk7XG4gICAgICAgIH0pLCBSZWFjdC5jcmVhdGVFbGVtZW50KCdkaXYnLCB7IGNsYXNzTmFtZTogJ3BhZ2UnIH0sIFJlYWN0LmNyZWF0ZUVsZW1lbnQoJ2Zvcm0nLCBudWxsLCB0aGlzLnByb3BzLmNoaWxkcmVuKSkpO1xuICAgIH1cbn0pO1xuXG5tb2R1bGUuZXhwb3J0cyA9IEZvcm07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9jb21wb25lbnRzL2Zvcm0uanNcbi8vIG1vZHVsZSBpZCA9IDE3NFxuLy8gbW9kdWxlIGNodW5rcyA9IDQiLCIndXNlIHN0cmljdCc7XG5cbnZhciBSZWFjdCA9IHJlcXVpcmUoJ3JlYWN0JyksXG4gICAgZmx1eCA9IHJlcXVpcmUoJ2ZsdXhpZnknKTtcblxudmFyIFBhZ2VMYWJlbCA9IFJlYWN0LmNyZWF0ZUNsYXNzKHtcbiAgICBkaXNwbGF5TmFtZTogJ1BhZ2VMYWJlbCcsXG4gICAgZ2V0SW5pdGlhbFN0YXRlOiBmdW5jdGlvbiBnZXRJbml0aWFsU3RhdGUoKSB7XG4gICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICAgICAgfTtcbiAgICB9LFxuXG4gICAgY29tcG9uZW50RGlkTW91bnQ6IGZ1bmN0aW9uIGNvbXBvbmVudERpZE1vdW50KCkge1xuICAgICAgICB2YXIgc2VsZiA9IHRoaXM7XG4gICAgICAgIC8vICAgICAgY29uc29sZS5sb2coJ3BhZ2UgbGFiZWwgY29tcG9uZW50V2lsbE1vdW50JylcbiAgICAgICAgZmx1eC5zdG9yZXMuZG9jU3RvcmUub24oJ2NoYW5nZTplZGl0ZWQnLCBmdW5jdGlvbiAobmV3VmFsdWUsIHByZXZpb3VzVmFsdWUpIHtcbiAgICAgICAgICAgIHNlbGYuc2V0U3RhdGUoeyBkaXNhYmxlZDogbmV3VmFsdWUgfSk7XG4gICAgICAgIH0pO1xuICAgIH0sXG5cbiAgICBoYW5kbGVDbGljazogZnVuY3Rpb24gaGFuZGxlQ2xpY2socGFnZSkge1xuICAgICAgICAvLyDQvtCx0YDQsNCx0L7RgtGH0LjQuiDQvdCwINGB0L7QsdGL0YLQuNC1INC60LvQuNC6LCDQv9C+0LTQs9GA0YPQttCw0LXQvCDRgdCy0Y/Qt9Cw0L3QvdGL0Lkg0LTQvtC60YPQvNC10L3RglxuICAgICAgICAvLyAgICAgICBhbGVydCgnY2xpY2s6JyArIHBhZ2VOYW1lKTtcbiAgICAgICAgLy8gZG9jVHlwZUlkOiBkb2MuZG9jX3R5cGUsIGRvY0lkOmRvYy5pZCwgcGFnZU5hbWU6J0xhdXNlbmQgaWQ6JyArIGRvYy5pZFxuXG4gICAgICAgIGlmICh0aGlzLnN0YXRlLmRpc2FibGVkKSB7XG4gICAgICAgICAgICBjb25zb2xlLmxvZygncGFnZSBkaXNhYmxlZCcpO1xuICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgaWYgKHBhZ2UuZG9jSWQpIHtcbiAgICAgICAgICAgIGNvbnNvbGUubG9nKCdoYW5kbGVDbGljayBwYWdlLmRvY1R5cGVJZCAlcywgcGFnZS5kb2NJZCAlbicpO1xuICAgICAgICAgICAgdmFyIHVybCA9IFwiL2RvY3VtZW50L1wiICsgcGFnZS5kb2NUeXBlSWQgKyBwYWdlLmRvY0lkO1xuICAgICAgICAgICAgZG9jdW1lbnQubG9jYXRpb24uaHJlZiA9IHVybDtcbiAgICAgICAgfVxuICAgIH0sXG5cbiAgICByZW5kZXI6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgdmFyIGNsYXNzTmFtZSA9ICdwYWdlTGFiZWwnO1xuXG4gICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KCdsYWJlbCcsIHsgY2xhc3NOYW1lOiBjbGFzc05hbWUsIG9uQ2xpY2s6IHRoaXMuaGFuZGxlQ2xpY2suYmluZCh0aGlzLCB0aGlzLnByb3BzLmNoaWxkcmVuKSwgZGlzYWJsZWQ6IHRoaXMuc3RhdGUuZGlzYWJsZWQgfSwgdGhpcy5wcm9wcy5jaGlsZHJlbi5wYWdlTmFtZSwgJyAnKTtcbiAgICB9XG59KTtcblxubW9kdWxlLmV4cG9ydHMgPSBQYWdlTGFiZWw7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9jb21wb25lbnRzL3BhZ2VfbGFiZWwuanNcbi8vIG1vZHVsZSBpZCA9IDE3NVxuLy8gbW9kdWxlIGNodW5rcyA9IDQiXSwibWFwcGluZ3MiOiI7Ozs7OztBQUFBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDZkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNyMEJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNyQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQ2hCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUN2QkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7Ozs7OztBQzVCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7OzsiLCJzb3VyY2VSb290IjoiIn0=