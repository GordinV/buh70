var docs =
webpackJsonp_name_([5],{

/***/ 0:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var Register = __webpack_require__(176);

	// данные для хранилища
	//localStorage['docsStore'] = storeData;
	storeData = JSON.parse(storeData);
	userData = JSON.parse(userData);

	ReactDOM.hydrate(React.createElement(Register, { id: 'grid', components: storeData, userData: userData }, 'Тут будут компоненты'), document.getElementById('grid'));

/***/ }),

/***/ 176:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';
	// грузим компоненты

	//import PropTypes from 'prop-types';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(3);

	var React = __webpack_require__(13),
	    flux = __webpack_require__(43),
	    DataGrid = __webpack_require__(88),
	    BtnAdd = __webpack_require__(66),
	    BtnEdit = __webpack_require__(67),
	    BtnDelete = __webpack_require__(90),
	    BtnPrint = __webpack_require__(70),
	    BtnFilter = __webpack_require__(163),
	    ModalPage = __webpack_require__(158),
	    ModalPageDelete = __webpack_require__(177),
	    ModalPageInfo = __webpack_require__(179),
	    TreeList = __webpack_require__(63),
	    Sidebar = __webpack_require__(181),
	    MenuToolBar = __webpack_require__(183),
	    ToolbarContainer = __webpack_require__(51),
	    styles = __webpack_require__(184),
	    GridFilter = __webpack_require__(164);

	// Create a store
	var docsStore = __webpack_require__(185);

	// создаем класс - держатель состояний

	var Register = function (_React$PureComponent) {
	    _inherits(Register, _React$PureComponent);

	    function Register(props) {
	        _classCallCheck(this, Register);

	        var _this = _possibleConstructorReturn(this, (Register.__proto__ || Object.getPrototypeOf(Register)).call(this, props));

	        _this.state = {
	            // у каждого компонента свой объект
	            getFilter: false,
	            getDeleteModalPage: false,
	            showSystemMessage: false,
	            activRowId: 0,
	            isReport: false,
	            treeValue: _this.findComponent('docsList')[0].value,
	            gridValue: 0
	        };

	        _this.treeData = {
	            data: _this.findComponent('docsList')[0].data || []
	        };

	        _this.gridData = {
	            data: _this.findComponent('docsGrid')[0].data[0].data,
	            gridConfig: _this.findComponent('docsGrid')[0].data[0].columns
	        };

	        _this.filterData = []; // массив объектов, куда запишем параметры для фильтрации @todo вынести все в отдельный компонет для фильтрации

	        _this.btnAddClick = _this.btnAddClick.bind(_this);
	        _this.btnEditClick = _this.btnEditClick.bind(_this);
	        _this.btnDeleteClick = _this.btnDeleteClick.bind(_this);
	        _this.btnPrintClick = _this.btnPrintClick.bind(_this);
	        _this.btnFilterClick = _this.btnFilterClick.bind(_this);
	        _this.modalPageBtnClick = _this.modalPageBtnClick.bind(_this);
	        _this.modalPageDelBtnClick = _this.modalPageDelBtnClick.bind(_this);
	        _this.clickHandler = _this.clickHandler.bind(_this);
	        _this.dblClickHandler = _this.dblClickHandler.bind(_this);
	        _this.headerClickHandler = _this.headerClickHandler.bind(_this);
	        _this.isReports = _this.isReports.bind(_this);

	        return _this;
	    }

	    _createClass(Register, [{
	        key: 'componentDidMount',
	        value: function componentDidMount() {
	            var _this2 = this;

	            var self = this;
	            window.addEventListener('beforeunload', this.componentCleanup);

	            // отслеживаем изменение фильтра
	            docsStore.on('change:sqlWhere', function (newValue) {
	                // данные изменились, обнуляем данные фильтра
	                if (!newValue) {
	                    self.filterData = [];
	                }
	            });

	            // создаем обработчик события на изменение даннх
	            docsStore.on('change:data', function (newValue) {
	                // данные изменились, меняем состояние
	                _this2.gridData = {
	                    data: newValue[1].data[0].data,
	                    gridConfig: newValue[1].data[0].columns
	                };

	                _this2.treeData = {
	                    data: newValue[0].data
	                };

	                if (_this2.state.gridValue !== newValue[1].lastDocId) {
	                    self.setState({ gridValue: newValue[1].lastDocId });
	                } else {
	                    self.forceUpdate();
	                }
	            });

	            // создаем обработчик события на изменение строки грида
	            docsStore.on('change:docsGrid', function (newValue, previousValue) {
	                // данные изменились, меняем состояние
	                self.setState({ gridValue: newValue });
	            });

	            // создаем обработчик события на изменение строки грида
	            docsStore.on('change:docsList', function (newValue, previousValue) {
	                // данные изменились, меняем состояние
	                self.setState({ treeValue: newValue });
	            });

	            // создаем обработчик события системный извещение
	            docsStore.on('change:systemMessage', function (newValue, previousValue) {
	                // данные изменились, меняем состояние
	                self.setState({ showSystemMessage: !!newValue });
	            });

	            // покажем данные

	            //        let lastComponent = localStorage['docsList'];
	            flux.doAction('dataChange', this.props.components);
	        }

	        /**
	         * снимет все подписки
	         */

	    }, {
	        key: 'componentCleanup',
	        value: function componentCleanup() {
	            docsStore.off('change:sqlWhere');
	            docsStore.off('change:systemMessage');
	            docsStore.off('change:docsList');
	            docsStore.off('change:docsGrid');
	            docsStore.off('change:data');
	            docsStore.off('change:sqlWhere');
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var systemMessage = docsStore.systemMessage;

	            this.getFilterFields();

	            var btnParams = {
	                btnStart: {
	                    show: false
	                },
	                btnLogin: {
	                    show: true
	                }
	            };

	            return React.createElement(
	                'div',
	                { ref: 'parentDiv' },
	                MenuToolBar(btnParams, this.props.userData),
	                this.renderFilterToolbar(),
	                React.createElement(
	                    'div',
	                    { ref: 'docContainer', style: styles.container },
	                    this.renderDocToolBar(),
	                    React.createElement(
	                        'div',
	                        { style: styles.wrapper },
	                        React.createElement(
	                            Sidebar,
	                            { width: '30%', toolbar: true, ref: 'list-sidebar' },
	                            React.createElement(TreeList, { ref: 'treeList',
	                                data: this.treeData['data'],
	                                name: 'docsList',
	                                bindDataField: 'kood',
	                                value: this.state.treeValue,
	                                onClickAction: this.clickHandler,
	                                onChangeAction: 'docsListChange'
	                            })
	                        ),
	                        React.createElement(
	                            'div',
	                            { style: styles.container },
	                            this.renderAruannePage(),
	                            React.createElement(
	                                Sidebar,
	                                { toolbar: false, ref: 'grid-sidebar', height: '400px' },
	                                React.createElement(DataGrid, { ref: 'dataGrid',
	                                    gridData: this.gridData['data'],
	                                    gridColumns: this.gridData['gridConfig'],
	                                    onChangeAction: 'docsGridChange',
	                                    onClick: this.clickHandler,
	                                    onDblClick: this.dblClickHandler,
	                                    onHeaderClick: this.headerClickHandler,
	                                    value: this.state.gridValue,
	                                    url: 'api' }),
	                                React.createElement(
	                                    ModalPage,
	                                    { ref: 'modalpageFilter',
	                                        modalPageBtnClick: this.modalPageBtnClick,
	                                        modalPageName: 'Filter',
	                                        show: this.state.getFilter },
	                                    React.createElement(GridFilter, { ref: 'gridFilter',
	                                        gridConfig: this.gridData['gridConfig'],
	                                        data: this.filterData })
	                                ),
	                                React.createElement(ModalPageDelete, { ref: 'modalpageDelete',
	                                    modalPageBtnClick: this.modalPageDelBtnClick,
	                                    show: this.state.getDeleteModalPage }),
	                                React.createElement(ModalPageInfo, { ref: 'modalpageInfo',
	                                    modalPageBtnClick: this.modalPageInfoBtnClick,
	                                    show: this.state.showSystemMessage,
	                                    systemMessage: systemMessage })
	                            )
	                        )
	                    )
	                )
	            );
	        }

	        /**
	         * Вернет компонент Отчет, если выбранная ветка содержит тип == aruanne
	         * @returns {boolean|XML}
	         */

	    }, {
	        key: 'renderAruannePage',
	        value: function renderAruannePage() {
	            var isReport = this.isReports(this.state.treeValue);
	            var Component = React.createElement(
	                Sidebar,
	                { toolbar: true, ref: 'aruanne-sidebar', height: '100%' },
	                'Aruanne'
	            );
	            return isReport && Component;
	        }

	        /**
	         * Вернет компонет - панель инструментов документа
	         * @returns {XML}
	         */

	    }, {
	        key: 'renderDocToolBar',
	        value: function renderDocToolBar() {
	            var toolbarParams = this.prepareParamsForToolbar(); //параметры для кнопок управления, взависимости от активной строки

	            return React.createElement(
	                ToolbarContainer,
	                { ref: 'toolbarContainer' },
	                React.createElement(
	                    'div',
	                    null,
	                    React.createElement(BtnAdd, { onClick: this.btnAddClick, show: toolbarParams['btnAdd'].show,
	                        disable: toolbarParams['btnAdd'].disabled }),
	                    React.createElement(BtnEdit, { onClick: this.btnEditClick, show: toolbarParams['btnEdit'].show,
	                        disable: toolbarParams['btnEdit'].disabled }),
	                    React.createElement(BtnDelete, { onClick: this.btnDeleteClick, show: toolbarParams['btnDelete'].show,
	                        disable: toolbarParams['btnDelete'].disabled }),
	                    React.createElement(BtnPrint, { onClick: this.btnPrintClick, show: toolbarParams['btnPrint'].show,
	                        disable: toolbarParams['btnPrint'].disabled }),
	                    React.createElement(BtnFilter, { onClick: this.btnFilterClick })
	                )
	            );
	        }

	        /**
	         * Вернет компонет с данными строки фильтрации
	         * @returns {XML}
	         */

	    }, {
	        key: 'renderFilterToolbar',
	        value: function renderFilterToolbar() {
	            var filter = this.getFilterString();
	            var component = void 0;

	            if (filter) {
	                component = React.createElement(
	                    ToolbarContainer,
	                    { ref: 'filterToolbarContainer', position: 'left' },
	                    React.createElement(
	                        'span',
	                        null,
	                        ' Filter: ',
	                        this.getFilterString()
	                    )
	                );
	            }

	            return component;
	        }

	        /**
	         * Проанализирует свойства выбранного документа и вернет true , если тип == Aruanne
	         * @param document
	         * @returns {boolean}
	         */

	    }, {
	        key: 'isReports',
	        value: function isReports(document) {
	            var data = this.findComponent('docsList')[0].data,
	                documentData = data.filter(function (row) {
	                return row.kood === document && row.props && JSON.parse(row.props).type === 'aruanne';
	            });

	            return !!documentData.length;
	        }
	    }, {
	        key: 'findComponent',
	        value: function findComponent(componentName) {
	            // вернет данные компонента по его названию
	            var componentData = [];

	            if (this.props.components.length > 0) {
	                componentData = this.props.components.filter(function (item) {
	                    if (item.name == componentName) {
	                        return item;
	                    }
	                });
	            }

	            if (!componentData[0].name == 'docsGrid' && componentData[0].lastDocId == '0' && !flux.stores.docsStore.docsGrid) {
	                componentData[0].lastDocid = componentData[0].data[0].id || 0;
	                // сохраним номер в сторе
	                flux.doAction('docsGridChange', componentData[0].data[0].id || 0);
	            }

	            return componentData;
	        }
	    }, {
	        key: 'btnFilterClick',
	        value: function btnFilterClick() {
	            // откроет модальное окно с полями для фильтрации
	            this.setState({ getFilter: true });
	        }
	    }, {
	        key: 'btnDeleteClick',
	        value: function btnDeleteClick() {
	            this.setState({ getDeleteModalPage: true });
	        }
	    }, {
	        key: 'btnAddClick',
	        value: function btnAddClick() {
	            // обработчик события клик кнопки "Добавить"
	            // вызовем действия на флаксе
	            flux.doAction('Add');
	        }
	    }, {
	        key: 'btnEditClick',
	        value: function btnEditClick() {
	            // обработчик события клик кнопки "Изменить"
	            // вызовем действия на флаксе
	            flux.doAction('Edit');
	        }
	    }, {
	        key: 'btnPrintClick',
	        value: function btnPrintClick() {
	            // обработчик события клик кнопки "Изменить"
	            // вызовем действия на флаксе
	            flux.doAction('Print');
	        }
	    }, {
	        key: 'clickHandler',
	        value: function clickHandler(action, id) {
	            // сохраним в хранилище
	            if (action && id) {
	                flux.doAction(action, id);
	            }
	            if (action == 'docsGridChange') {
	                this.gridData.value = id;
	                this.setState({ gridValue: id });
	            } else {
	                this.treeData.value = id;
	                this.setState({ treeValue: id });
	            }
	        }
	    }, {
	        key: 'dblClickHandler',
	        value: function dblClickHandler() {
	            // вызовет метод редактирования
	            flux.doAction('Edit');
	        }
	    }, {
	        key: 'headerClickHandler',
	        value: function headerClickHandler(sortBy) {
	            flux.doAction('sortByChange', sortBy);
	        }
	    }, {
	        key: 'modalPageBtnClick',
	        value: function modalPageBtnClick(btnEvent) {
	            // обработчик для кнопки фильтрации
	            var filterString = '';
	            if (btnEvent == 'Ok') {
	                // собираем данные
	                var gridFilter = this.refs['gridFilter'],
	                    filterData = gridFilter.state.data;

	                this.filterData = filterData.map(function (row) {
	                    if (row.value) {
	                        filterString = filterString + (filterString.length > 0 ? " and " : " where ");
	                        switch (row.type) {

	                            case 'text':
	                                filterString = filterString + row.refs + " ilike '%" + row.value + "%'";
	                                break;
	                            case 'string':
	                                filterString = filterString + row.refs + " ilike '" + row.value + "%'";
	                                break;
	                            case 'date':
	                                filterString = filterString + row.refs + " = '" + row.value + "'";
	                                break;
	                            case 'number':
	                                filterString = filterString + row.refs + " = " + row.value;
	                                break;
	                            case 'integer':
	                                filterString = filterString + row.refs + " = " + row.value;
	                                break;
	                        }
	                    }
	                    return row;
	                }, this);
	                // применем фильтр
	                flux.doAction('sqlWhereChange', filterString);
	            }
	            this.setState({ getFilter: false });
	        }
	    }, {
	        key: 'modalPageDelBtnClick',
	        value: function modalPageDelBtnClick(btnEvent) {
	            // обработчик вызова модального окна удаления
	            this.setState({ getDeleteModalPage: false });

	            if (btnEvent == 'Ok') {
	                // вызовем действия на флаксе
	                flux.doAction('Delete');
	            }
	        }
	    }, {
	        key: 'modalPageInfoBtnClick',
	        value: function modalPageInfoBtnClick() {

	            // обработчик вызова модального окна системного сообщения
	            this.setState({ showSystemMessage: false });
	            // вызовем действия на флаксе
	            flux.doAction('systemMessageChange', null);
	        }

	        /**
	         * создаст из полtй грида компоненты для формирования условий фильтрации
	         * @returns {Array|*}
	         */

	    }, {
	        key: 'getFilterFields',
	        value: function getFilterFields() {
	            var _this3 = this;

	            var gridComponents = docsStore.data,
	                gridData = [],
	                previosFilter = this.filterData;

	            for (var i = 0; i < gridComponents.length; i++) {
	                if (gridComponents[i]['name'] == 'docsGrid') {
	                    // ищем поле columns
	                    for (var field in gridComponents[i].data[0]) {
	                        if (field == 'columns') {
	                            gridData = gridComponents[i].data[0].columns;
	                            break;
	                        }
	                    }
	                    break;
	                }
	            }

	            if (gridData) {
	                this.filterData = []; // обнулим массив

	                gridData.map(function (row) {
	                    var componentType = 'text',
	                        componentObjektValue = void 0;

	                    for (var _i = 0; _i < previosFilter.length; _i++) {
	                        // ищем "старое" значение фильтра и если есть, то отдаем его value
	                        if (previosFilter[_i].refs == row.id) {
	                            componentObjektValue = previosFilter[_i].value;
	                            break;
	                        }
	                    }

	                    if (row.type) {
	                        componentType = row.type;
	                    }

	                    // соберем массив объектов
	                    _this3.filterData.push({
	                        name: row.name,
	                        value: componentObjektValue || null,
	                        type: componentType,
	                        refs: row.id
	                    });
	                });
	            }
	            return this.filterData;
	        }
	    }, {
	        key: 'getFilterString',
	        value: function getFilterString() {
	            // преобразует данные филтра в строку
	            var string = '';

	            this.filterData.map(function (row) {
	                if (row.value) {
	                    string = string + row.name + ':' + row.value + '; ';
	                }
	            });
	            return string;
	        }
	    }, {
	        key: 'prepareParamsForToolbar',
	        value: function prepareParamsForToolbar() {
	            var _this4 = this;

	            // читаем данные со стора, формируем параметры для кнопок управления, и туда их отдаем
	            //docsGridChange (flux.stores.docsStore.)
	            var grid = this.findComponent('docsGrid') || [],
	                lastRowId = this.state.activRowId,
	                data = [],
	                dataRow = [],
	                toolbarParams = {
	                btnAdd: {
	                    show: true,
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

	            // проверим наличие данных, если есть пропихнем компонентам

	            if (grid.length > 0 && grid[0].data.length > 0) {
	                data = grid[0].data[0].data;
	                dataRow = data.filter(function (row) {
	                    if (row.id === _this4.state.gridValue) {
	                        return row;
	                    }
	                });
	            } else {
	                return toolbarParams;
	            }

	            if (dataRow.length > 0 && dataRow[0].status == 'Проведен') {
	                // удалять нельзя
	                toolbarParams.btnDelete.show = false;
	            }
	            return toolbarParams;
	        }
	    }]);

	    return Register;
	}(React.PureComponent);

	Register.propTypes = {
	    components: PropTypes.array.isRequired
	};

	module.exports = Register;

/***/ }),

/***/ 177:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(3);

	var React = __webpack_require__(13),
	    ModalPage = __webpack_require__(158),
	    styles = __webpack_require__(178);

	var ModalPageDelete = function (_React$PureComponent) {
	    _inherits(ModalPageDelete, _React$PureComponent);

	    function ModalPageDelete(props) {
	        _classCallCheck(this, ModalPageDelete);

	        var _this = _possibleConstructorReturn(this, (ModalPageDelete.__proto__ || Object.getPrototypeOf(ModalPageDelete)).call(this, props));

	        _this.state = {
	            show: _this.props.show
	        };
	        return _this;
	    }

	    _createClass(ModalPageDelete, [{
	        key: 'componentWillReceiveProps',
	        value: function componentWillReceiveProps(nextProps) {
	            this.setState({ show: nextProps.show });
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var modalObjects = ['btnOk', 'btnCancel'];

	            return React.createElement(
	                ModalPage,
	                { ref: 'modalPage',
	                    modalPageBtnClick: this.props.modalPageBtnClick,
	                    show: this.state.show,
	                    modalPageName: 'Delete document' },
	                React.createElement(
	                    'div',
	                    { ref: 'container' },
	                    React.createElement('img', { ref: 'image', src: styles.icon }),
	                    React.createElement(
	                        'span',
	                        { ref: 'message' },
	                        ' \u0423\u0434\u0430\u043B\u0438\u0442\u044C \u0434\u043E\u043A\u0443\u043C\u0435\u043D\u0442 ? '
	                    )
	                )
	            );
	        }
	    }]);

	    return ModalPageDelete;
	}(React.PureComponent);
	/*
	ModalPageDelete.propTypes = {
	    modalPageBtnClick: PropTypes.func.isRequired
	}
	*/


	module.exports = ModalPageDelete;

/***/ }),

/***/ 178:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    icon: 'images/icons/delete.png'
	};

/***/ }),

/***/ 179:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(3);

	var React = __webpack_require__(13),
	    ModalPage = __webpack_require__(158),
	    styles = __webpack_require__(180);

	var ModalPageInfo = function (_React$PureComponent) {
	    _inherits(ModalPageInfo, _React$PureComponent);

	    function ModalPageInfo(props) {
	        _classCallCheck(this, ModalPageInfo);

	        var _this = _possibleConstructorReturn(this, (ModalPageInfo.__proto__ || Object.getPrototypeOf(ModalPageInfo)).call(this, props));

	        _this.state = {
	            show: _this.props.show
	        };

	        return _this;
	    }

	    _createClass(ModalPageInfo, [{
	        key: 'componentWillReceiveProps',
	        value: function componentWillReceiveProps(nextProps) {
	            this.setState({ show: nextProps.show });
	        }
	    }, {
	        key: 'render',
	        value: function render() {

	            var systemMessage = this.props.systemMessage ? this.props.systemMessage : '',
	                modalObjects = ['btnOk'];

	            return React.createElement(
	                ModalPage,
	                { ref: 'modalPage',
	                    modalPageBtnClick: this.props.modalPageBtnClick,
	                    modalPageName: 'Warning!',
	                    modalObjects: modalObjects },
	                React.createElement(
	                    'div',
	                    { ref: 'container' },
	                    React.createElement('img', { ref: 'image', src: styles.icon }),
	                    React.createElement(
	                        'span',
	                        null,
	                        ' ',
	                        systemMessage,
	                        ' '
	                    )
	                )
	            );
	        }
	    }]);

	    return ModalPageInfo;
	}(React.PureComponent);

	ModalPageInfo.propTypes = {
	    systemMessage: PropTypes.string,
	    modalPageBtnClick: PropTypes.func
	};

	module.exports = ModalPageInfo;

/***/ }),

/***/ 180:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    icon: 'images/icons/info.png'
	};

/***/ }),

/***/ 181:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

	var PropTypes = __webpack_require__(3);

	var sideBarStyles = __webpack_require__(182),
	    React = __webpack_require__(13);

	var SideBarContainer = function (_React$Component) {
	    _inherits(SideBarContainer, _React$Component);

	    function SideBarContainer(props) {
	        _classCallCheck(this, SideBarContainer);

	        var _this = _possibleConstructorReturn(this, (SideBarContainer.__proto__ || Object.getPrototypeOf(SideBarContainer)).call(this, props));

	        _this.state = {
	            width: props.width,
	            contentWidth: '100%',
	            show: true,
	            toolBar: props.toolbar
	        };

	        _this.btnClickHandler = _this.btnClickHandler.bind(_this);
	        return _this;
	    }

	    _createClass(SideBarContainer, [{
	        key: 'btnClickHandler',
	        value: function btnClickHandler() {
	            var width = this.state.show ? '20px' : this.props.width,
	                contentWidth = this.state.show ? '1px' : '100%',
	                showContent = !this.state.show;

	            this.setState({
	                width: width,
	                contentWidth: contentWidth,
	                show: showContent
	            });
	        }
	    }, {
	        key: 'render',
	        value: function render() {
	            var toolBarSymbol = this.state.show ? '<' : '>'; //@todo move to styles file

	            //prepaire styles
	            var sideBarContainerStyle = Object.assign({}, sideBarStyles.sideBarContainerStyle, { width: this.state.width }, { height: this.props.height }),
	                toolBarStyle = Object.assign({}, sideBarStyles.toolBarStyle, { visibility: this.props.toolbar ? 'visible' : 'hidden' }),
	                contentStyle = Object.assign({}, sideBarStyles.contentStyle, { visibility: this.state.show ? 'visible' : 'hidden' }),
	                buttonStyle = Object.assign({}, sideBarStyles.buttonStyle, {
	                height: this.props.toolbar ? sideBarStyles.buttonStyle.height : '0',
	                visibility: this.props.toolbar ? 'visible' : 'hidden'
	            });

	            return React.createElement(
	                'div',
	                { id: 'toolBarContainer', style: sideBarContainerStyle, ref: 'toolbar' },
	                React.createElement(
	                    'div',
	                    { id: 'btnBar', style: toolBarStyle },
	                    React.createElement('input', { type: 'button',
	                        ref: 'sidebar-button',
	                        style: buttonStyle,
	                        value: toolBarSymbol,
	                        onClick: this.btnClickHandler
	                    })
	                ),
	                React.createElement(
	                    'div',
	                    { id: 'content', style: contentStyle, ref: 'content' },
	                    this.props.children
	                )
	            );
	        }
	    }]);

	    return SideBarContainer;
	}(React.Component);

	SideBarContainer.propTypes = {
	    toolbar: PropTypes.bool,
	    width: PropTypes.string,
	    heigth: PropTypes.string
	};

	SideBarContainer.defaultProps = {
	    toolbar: true,
	    width: '100%',
	    height: '100%'
	};

	module.exports = SideBarContainer;

/***/ }),

/***/ 182:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    sideBarContainerStyle: {
	        width: '100%',
	        height: '500px',
	        /*
	                border:'1px solid grey',
	        */
	        background: 'white'
	    },

	    toolBarStyle: {
	        display: 'flex',
	        height: 'auto',
	        width: '100%',
	        border: '1px solid black',
	        background: 'gray',
	        visibility: 'visible'
	    },
	    contentStyle: {
	        height: 'inherit',
	        width: '100%'
	    },

	    buttonStyle: {
	        position: 'relative',
	        height: '20px',
	        width: '20px'
	    }
	};

/***/ }),

/***/ 183:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';
	/**
	 * Вернет компонет для toolbarMenu
	 * @btnParams Параметры кнопок
	 * @userData Данные пользователя
	 * @returns {XML}
	 */

	var React = __webpack_require__(13);
	var MenuToolBar = __webpack_require__(53);
	var rendermenuToolBar = function rendermenuToolBar(btnParams, userData) {
	    return React.createElement(
	        'div',
	        null,
	        React.createElement(MenuToolBar, { edited: false, params: btnParams, userData: userData, btnStartClick: undefined.btnStartClickHanler })
	    );
	};

	module.exports = rendermenuToolBar;

/***/ }),

/***/ 184:
/***/ (function(module, exports) {

	'use strict';

	module.exports = {
	    container: {
	        display: 'flex',
	        flexFlow: 'row wrap',
	        height: '87%'
	        /*
	                border: '3px solid brown'
	        */
	    },
	    wrapper: {
	        display: 'flex',
	        height: '100%',
	        flex: '1 100%',
	        alignItems: 'stretch',
	        flexDirection: 'row'
	    }
	};

/***/ }),

/***/ 185:
/***/ (function(module, exports, __webpack_require__) {

	'use strict';

	var flux = __webpack_require__(43),
	    ORDER_BY = [{ column: 'id', direction: 'desc' }];

	var docsStore = flux.createStore({
	    id: 'docsStore',
	    initialState: {
	        docsGrid: 0,
	        docsList: '',
	        name: 'vlad',
	        data: [],
	        sortBy: ORDER_BY,
	        sqlWhere: '',
	        systemMessage: null,
	        userData: {},
	        logedIn: false
	    },
	    actionCallbacks: {
	        systemMessageChange: function systemMessageChange(updater, value) {
	            updater.set({ systemMessage: value });
	        },
	        sqlWhereChange: function sqlWhereChange(updater, value) {
	            updater.set({ sqlWhere: value });
	            requery({ name: 'docsGrid', value: this.docsList });
	        },
	        sortByChange: function sortByChange(updater, value) {
	            updater.set({ sortBy: value });
	            requery({ name: 'docsGrid', value: this.docsList, sortBy: value });
	        },
	        Add: function Add() {
	            add(this.docsList);
	        },
	        Edit: function Edit() {
	            if (this.docsList && this.docsGrid) {
	                edit(this.docsList, this.docsGrid);
	            } else {
	                console.error('Тип документа или документ не выбран', this.docsList, this.docsGrid);
	            }
	        },
	        Delete: function Delete() {
	            var docTypeId = this.docsList;
	            requeryForAction('delete', function (err, data) {
	                if (err) {
	                    flux.doAction('systemMessageChange', err); // пишем изменения в хранилище
	                } else {
	                    flux.doAction('systemMessageChange', null); // пишем изменения в хранилище
	                    requery({ name: 'docsGrid', value: docTypeId });
	                }
	            });
	        },
	        Print: function Print() {
	            console.log('button Print cliked!');
	        },
	        changeName: function changeName(updater, name) {
	            // Stores updates are only made inside store's action callbacks
	            updater.set({ name: name });
	        },
	        docsGridChange: function docsGridChange(updater, value) {
	            // Stores updates are only made inside store's action callbacks
	            updater.set({ docsGrid: value });
	        },
	        docsListChange: function docsListChange(updater, value) {
	            // Stores updates are only made inside store's action callbacks
	            var lastValue = flux.stores.docsStore.docsList || 'DOK';
	            if (value !== lastValue) {
	                updater.set({ docsList: value });
	            }
	            flux.doAction('sqlWhereChange', '');
	            flux.doAction('sortByChange', ORDER_BY);
	            requery({ name: 'docsGrid', value: value });

	            //            localStorage['docsList'] = value;
	        },
	        dataChange: function dataChange(updater, value) {
	            // Stores updates are only made inside store's action callbacks
	            updater.set({ data: value });

	            if (!this.docsGrid) {
	                var gridValue = value[1].data[0].data[0].id;
	                flux.doAction('docsGridChange', gridValue);
	            }

	            if (!this.docsList) {
	                var treeValue = value[0].value;
	                flux.doAction('docsListChange', treeValue);
	            }
	        },
	        userDataChange: function userDataChange(updater, value) {
	            updater.set({ userData: value });

	            var logedIn = !!userData;
	            updater.set({ logedIn: logedIn });
	        }

	    }
	});

	var edit = function edit(docTypeId, docId) {
	    document.location.href = "/document/" + docTypeId + docId;
	};

	var add = function add(docTypeId) {
	    document.location.href = "/document/" + docTypeId + '0';
	};

	var requeryForAction = function requeryForAction(action, callback) {
	    var ACTION_LIST = { 'delete': 'DELETE' },
	        API = '/api/doc';
	    if (!window.jQuery || !$) return; // для тестов

	    // метод обеспечит запрос на выполнение
	    var docId = docsStore.docsGrid,
	        docTypeId = docsStore.docsList;

	    if (!docId || typeof docId == 'string') {
	        docId = 0;
	    }

	    if (!docId) {
	        // doc not selected
	        var data = docsStore.data;
	        data.forEach(function (row) {
	            //@todo Привести в божеский вид
	            if (!docTypeId && row.name == 'docsList') {
	                // не назначен тип документа
	                docTypeId = row['value'];
	                flux.doAction('docsListChange', docTypeId);
	            }

	            if (row.name == 'docsGrid') {
	                docId = row.data[0].data[0].id;
	                flux.doAction('docsGridChange', docId);
	            }
	        });
	    }

	    var parameters = {
	        docId: docId,
	        doc_type_id: docTypeId
	    };

	    $.ajax({
	        url: API,
	        type: ACTION_LIST[ACTION] || 'POST',
	        dataType: 'json',
	        data: {
	            action: action,
	            data: JSON.stringify(parameters)
	        },
	        cache: false,
	        success: function success(data) {
	            // должны получить объект - результат
	            var errorMesssage = null;
	            if (data.result == 'Error') {
	                errorMesssage = 'Error, ' + data.message;
	            }

	            callback(errorMesssage, data);
	        },
	        error: function error(xhr, status, err) {
	            console.error('/error', status, err.toString());
	            callback(err, null);
	        }
	    });
	};

	var requery = function requery(component) {
	    if (!window.jQuery) return; // для тестов

	    // метод обеспечит получение данных от сервера
	    // component = this.state.components[name]
	    // если параметры не заданы, грузим все

	    var components = docsStore.data;

	    // фильтруем список компонентов
	    var componentsForUpdate = components.filter(function (item) {
	        // ищем объект по наименованию. или вернем все если параметр не задан
	        if (component.name == '' || item.name == component.name) {
	            return item.name;
	        }
	    });

	    // сортировка
	    var sqlSortBy = '',
	        sqlWhere = docsStore.sqlWhere || '',
	        sortByArray = docsStore.sortBy;

	    if (docsStore.sortBy) {
	        for (var i = 0; i < sortByArray.length; i++) {
	            if (i > 0) {
	                sqlSortBy = sqlSortBy + ',';
	            }
	            sqlSortBy = sqlSortBy + sortByArray[i].column + ' ' + sortByArray[i].direction;
	        }
	    }

	    var URL = '/api/docs';
	    $.ajax({
	        url: URL,
	        type: "POST",
	        dataType: 'json',

	        data: {
	            dataType: 'component',
	            docTypeId: 1,
	            components: JSON.stringify(componentsForUpdate), // компоненты для обновления
	            parameter: component.value, // параметры
	            sortBy: sqlSortBy, // сортировка
	            lastDocId: docsStore.docsGrid,
	            sqlWhere: sqlWhere // динамический фильтр грида
	        },
	        cache: false,
	        success: function (data) {
	            // должны получить объект
	            var components = [];
	            data.forEach(function (item) {
	                // find item
	                // обновим данные массива компонентов
	                components = docsStore.data.map(function (component) {
	                    if (component.name == item.name) {
	                        // found
	                        component.data = item.data;
	                    }
	                    return component;
	                });
	            });
	            flux.doAction('dataChange', components);
	        }.bind(undefined),
	        error: function (xhr, status, err) {
	            console.error('/error', status, err.toString());
	        }.bind(undefined)
	    });
	};

	module.exports = docsStore;

/***/ })

});
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZG9jcy5qcyIsInNvdXJjZXMiOlsid2VicGFjazovLy8uL2Zyb250ZW5kL2RvY3MuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvZG9jcy9kb2MtcmVnaXN0ZXIvZG9jLXJlZ2lzdGVyLmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9jb21wb25lbnRzL21vZGFscGFnZS9tb2RhbHBhZ2UtZGVsZXRlL21vZGFsUGFnZS1kZWxldGUuanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2NvbXBvbmVudHMvbW9kYWxwYWdlL21vZGFscGFnZS1kZWxldGUvbW9kYWxwYWdlLWRlbGV0ZS1zdHlsZXMuanMiLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvY29tcG9uZW50cy9tb2RhbHBhZ2UvbW9kYWxwYWdlLWluZm8vbW9kYWxQYWdlLWluZm8uanN4Iiwid2VicGFjazovLy8uL2Zyb250ZW5kL2NvbXBvbmVudHMvbW9kYWxwYWdlL21vZGFscGFnZS1pbmZvL21vZGFscGFnZS1pbmZvLXN0eWxlcy5qcyIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9jb21wb25lbnRzL3NpZGViYXIvc2lkZWJhci5qc3giLCJ3ZWJwYWNrOi8vLy4vZnJvbnRlbmQvY29tcG9uZW50cy9zaWRlYmFyL3NpZGViYXItc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL21peGluL21lbnVUb29sQmFyLmpzeCIsIndlYnBhY2s6Ly8vLi9mcm9udGVuZC9kb2NzL2RvYy1yZWdpc3Rlci9kb2MtcmVnaXN0ZXItc3R5bGVzLmpzIiwid2VicGFjazovLy8uL2Zyb250ZW5kL3N0b3Jlcy9kb2NzX3N0b3JlLmpzIl0sInNvdXJjZXNDb250ZW50IjpbIid1c2Ugc3RyaWN0JztcblxudmFyIFJlZ2lzdGVyID0gcmVxdWlyZSgnLi4vZnJvbnRlbmQvZG9jcy9kb2MtcmVnaXN0ZXIvZG9jLXJlZ2lzdGVyLmpzeCcpO1xuXG4vLyDQtNCw0L3QvdGL0LUg0LTQu9GPINGF0YDQsNC90LjQu9C40YnQsFxuLy9sb2NhbFN0b3JhZ2VbJ2RvY3NTdG9yZSddID0gc3RvcmVEYXRhO1xuc3RvcmVEYXRhID0gSlNPTi5wYXJzZShzdG9yZURhdGEpO1xudXNlckRhdGEgPSBKU09OLnBhcnNlKHVzZXJEYXRhKTtcblxuUmVhY3RET00uaHlkcmF0ZShSZWFjdC5jcmVhdGVFbGVtZW50KFJlZ2lzdGVyLCB7IGlkOiAnZ3JpZCcsIGNvbXBvbmVudHM6IHN0b3JlRGF0YSwgdXNlckRhdGE6IHVzZXJEYXRhIH0sICfQotGD0YIg0LHRg9C00YPRgiDQutC+0LzQv9C+0L3QtdC90YLRiycpLCBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgnZ3JpZCcpKTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2RvY3MuanNcbi8vIG1vZHVsZSBpZCA9IDBcbi8vIG1vZHVsZSBjaHVua3MgPSA1IiwiJ3VzZSBzdHJpY3QnO1xuLy8g0LPRgNGD0LfQuNC8INC60L7QvNC/0L7QvdC10L3RgtGLXG5cbi8vaW1wb3J0IFByb3BUeXBlcyBmcm9tICdwcm9wLXR5cGVzJztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpLFxuICAgIGZsdXggPSByZXF1aXJlKCdmbHV4aWZ5JyksXG4gICAgRGF0YUdyaWQgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvZGF0YS1ncmlkL2RhdGEtZ3JpZC5qc3gnKSxcbiAgICBCdG5BZGQgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi1yZWdpc3Rlci1hZGQvYnV0dG9uLXJlZ2lzdGVyLWFkZC5qc3gnKSxcbiAgICBCdG5FZGl0ID0gcmVxdWlyZSgnLi8uLi8uLi9jb21wb25lbnRzL2J1dHRvbi1yZWdpc3Rlci9idXR0b24tcmVnaXN0ZXItZWRpdC9idXR0b24tcmVnaXN0ZXItZWRpdC5qc3gnKSxcbiAgICBCdG5EZWxldGUgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi1yZWdpc3Rlci1kZWxldGUvYnV0dG9uLXJlZ2lzdGVyLWRlbGV0ZS5qc3gnKSxcbiAgICBCdG5QcmludCA9IHJlcXVpcmUoJy4vLi4vLi4vY29tcG9uZW50cy9idXR0b24tcmVnaXN0ZXIvYnV0dG9uLXJlZ2lzdGVyLXByaW50L2J1dHRvbi1yZWdpc3Rlci1wcmludC5qc3gnKSxcbiAgICBCdG5GaWx0ZXIgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvYnV0dG9uLXJlZ2lzdGVyL2J1dHRvbi1yZWdpc3Rlci1maWx0ZXIvYnV0dG9uLXJlZ2lzdGVyLWZpbHRlci5qc3gnKSxcbiAgICBNb2RhbFBhZ2UgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvbW9kYWxwYWdlL21vZGFsUGFnZS5qc3gnKSxcbiAgICBNb2RhbFBhZ2VEZWxldGUgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvbW9kYWxwYWdlL21vZGFscGFnZS1kZWxldGUvbW9kYWxQYWdlLWRlbGV0ZS5qc3gnKSxcbiAgICBNb2RhbFBhZ2VJbmZvID0gcmVxdWlyZSgnLi8uLi8uLi9jb21wb25lbnRzL21vZGFscGFnZS9tb2RhbHBhZ2UtaW5mby9tb2RhbFBhZ2UtaW5mby5qc3gnKSxcbiAgICBUcmVlTGlzdCA9IHJlcXVpcmUoJy4vLi4vLi4vY29tcG9uZW50cy90cmVlL3RyZWUuanN4JyksXG4gICAgU2lkZWJhciA9IHJlcXVpcmUoJy4vLi4vLi4vY29tcG9uZW50cy9zaWRlYmFyL3NpZGViYXIuanN4JyksXG4gICAgTWVudVRvb2xCYXIgPSByZXF1aXJlKCcuLy4uLy4uL21peGluL21lbnVUb29sQmFyLmpzeCcpLFxuICAgIFRvb2xiYXJDb250YWluZXIgPSByZXF1aXJlKCcuLy4uLy4uL2NvbXBvbmVudHMvdG9vbGJhci1jb250YWluZXIvdG9vbGJhci1jb250YWluZXIuanN4JyksXG4gICAgc3R5bGVzID0gcmVxdWlyZSgnLi9kb2MtcmVnaXN0ZXItc3R5bGVzJyksXG4gICAgR3JpZEZpbHRlciA9IHJlcXVpcmUoJy4vLi4vLi4vY29tcG9uZW50cy9kYXRhLWdyaWQvZ3JpZC1maWx0ZXIvZ3JpZC1maWx0ZXIuanN4Jyk7XG5cbi8vIENyZWF0ZSBhIHN0b3JlXG52YXIgZG9jc1N0b3JlID0gcmVxdWlyZSgnLi8uLi8uLi9zdG9yZXMvZG9jc19zdG9yZS5qcycpO1xuXG4vLyDRgdC+0LfQtNCw0LXQvCDQutC70LDRgdGBIC0g0LTQtdGA0LbQsNGC0LXQu9GMINGB0L7RgdGC0L7Rj9C90LjQuVxuXG52YXIgUmVnaXN0ZXIgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoUmVnaXN0ZXIsIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIFJlZ2lzdGVyKHByb3BzKSB7XG4gICAgICAgIF9jbGFzc0NhbGxDaGVjayh0aGlzLCBSZWdpc3Rlcik7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKFJlZ2lzdGVyLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoUmVnaXN0ZXIpKS5jYWxsKHRoaXMsIHByb3BzKSk7XG5cbiAgICAgICAgX3RoaXMuc3RhdGUgPSB7XG4gICAgICAgICAgICAvLyDRgyDQutCw0LbQtNC+0LPQviDQutC+0LzQv9C+0L3QtdC90YLQsCDRgdCy0L7QuSDQvtCx0YrQtdC60YJcbiAgICAgICAgICAgIGdldEZpbHRlcjogZmFsc2UsXG4gICAgICAgICAgICBnZXREZWxldGVNb2RhbFBhZ2U6IGZhbHNlLFxuICAgICAgICAgICAgc2hvd1N5c3RlbU1lc3NhZ2U6IGZhbHNlLFxuICAgICAgICAgICAgYWN0aXZSb3dJZDogMCxcbiAgICAgICAgICAgIGlzUmVwb3J0OiBmYWxzZSxcbiAgICAgICAgICAgIHRyZWVWYWx1ZTogX3RoaXMuZmluZENvbXBvbmVudCgnZG9jc0xpc3QnKVswXS52YWx1ZSxcbiAgICAgICAgICAgIGdyaWRWYWx1ZTogMFxuICAgICAgICB9O1xuXG4gICAgICAgIF90aGlzLnRyZWVEYXRhID0ge1xuICAgICAgICAgICAgZGF0YTogX3RoaXMuZmluZENvbXBvbmVudCgnZG9jc0xpc3QnKVswXS5kYXRhIHx8IFtdXG4gICAgICAgIH07XG5cbiAgICAgICAgX3RoaXMuZ3JpZERhdGEgPSB7XG4gICAgICAgICAgICBkYXRhOiBfdGhpcy5maW5kQ29tcG9uZW50KCdkb2NzR3JpZCcpWzBdLmRhdGFbMF0uZGF0YSxcbiAgICAgICAgICAgIGdyaWRDb25maWc6IF90aGlzLmZpbmRDb21wb25lbnQoJ2RvY3NHcmlkJylbMF0uZGF0YVswXS5jb2x1bW5zXG4gICAgICAgIH07XG5cbiAgICAgICAgX3RoaXMuZmlsdGVyRGF0YSA9IFtdOyAvLyDQvNCw0YHRgdC40LIg0L7QsdGK0LXQutGC0L7Qsiwg0LrRg9C00LAg0LfQsNC/0LjRiNC10Lwg0L/QsNGA0LDQvNC10YLRgNGLINC00LvRjyDRhNC40LvRjNGC0YDQsNGG0LjQuCBAdG9kbyDQstGL0L3QtdGB0YLQuCDQstGB0LUg0LIg0L7RgtC00LXQu9GM0L3Ri9C5INC60L7QvNC/0L7QvdC10YIg0LTQu9GPINGE0LjQu9GM0YLRgNCw0YbQuNC4XG5cbiAgICAgICAgX3RoaXMuYnRuQWRkQ2xpY2sgPSBfdGhpcy5idG5BZGRDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuYnRuRWRpdENsaWNrID0gX3RoaXMuYnRuRWRpdENsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5idG5EZWxldGVDbGljayA9IF90aGlzLmJ0bkRlbGV0ZUNsaWNrLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5idG5QcmludENsaWNrID0gX3RoaXMuYnRuUHJpbnRDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuYnRuRmlsdGVyQ2xpY2sgPSBfdGhpcy5idG5GaWx0ZXJDbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMubW9kYWxQYWdlQnRuQ2xpY2sgPSBfdGhpcy5tb2RhbFBhZ2VCdG5DbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMubW9kYWxQYWdlRGVsQnRuQ2xpY2sgPSBfdGhpcy5tb2RhbFBhZ2VEZWxCdG5DbGljay5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuY2xpY2tIYW5kbGVyID0gX3RoaXMuY2xpY2tIYW5kbGVyLmJpbmQoX3RoaXMpO1xuICAgICAgICBfdGhpcy5kYmxDbGlja0hhbmRsZXIgPSBfdGhpcy5kYmxDbGlja0hhbmRsZXIuYmluZChfdGhpcyk7XG4gICAgICAgIF90aGlzLmhlYWRlckNsaWNrSGFuZGxlciA9IF90aGlzLmhlYWRlckNsaWNrSGFuZGxlci5iaW5kKF90aGlzKTtcbiAgICAgICAgX3RoaXMuaXNSZXBvcnRzID0gX3RoaXMuaXNSZXBvcnRzLmJpbmQoX3RoaXMpO1xuXG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG5cbiAgICBfY3JlYXRlQ2xhc3MoUmVnaXN0ZXIsIFt7XG4gICAgICAgIGtleTogJ2NvbXBvbmVudERpZE1vdW50JyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGNvbXBvbmVudERpZE1vdW50KCkge1xuICAgICAgICAgICAgdmFyIF90aGlzMiA9IHRoaXM7XG5cbiAgICAgICAgICAgIHZhciBzZWxmID0gdGhpcztcbiAgICAgICAgICAgIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyKCdiZWZvcmV1bmxvYWQnLCB0aGlzLmNvbXBvbmVudENsZWFudXApO1xuXG4gICAgICAgICAgICAvLyDQvtGC0YHQu9C10LbQuNCy0LDQtdC8INC40LfQvNC10L3QtdC90LjQtSDRhNC40LvRjNGC0YDQsFxuICAgICAgICAgICAgZG9jc1N0b3JlLm9uKCdjaGFuZ2U6c3FsV2hlcmUnLCBmdW5jdGlvbiAobmV3VmFsdWUpIHtcbiAgICAgICAgICAgICAgICAvLyDQtNCw0L3QvdGL0LUg0LjQt9C80LXQvdC40LvQuNGB0YwsINC+0LHQvdGD0LvRj9C10Lwg0LTQsNC90L3Ri9C1INGE0LjQu9GM0YLRgNCwXG4gICAgICAgICAgICAgICAgaWYgKCFuZXdWYWx1ZSkge1xuICAgICAgICAgICAgICAgICAgICBzZWxmLmZpbHRlckRhdGEgPSBbXTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgLy8g0YHQvtC30LTQsNC10Lwg0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0L3QsCDQuNC30LzQtdC90LXQvdC40LUg0LTQsNC90L3RhVxuICAgICAgICAgICAgZG9jc1N0b3JlLm9uKCdjaGFuZ2U6ZGF0YScsIGZ1bmN0aW9uIChuZXdWYWx1ZSkge1xuICAgICAgICAgICAgICAgIC8vINC00LDQvdC90YvQtSDQuNC30LzQtdC90LjQu9C40YHRjCwg0LzQtdC90Y/QtdC8INGB0L7RgdGC0L7Rj9C90LjQtVxuICAgICAgICAgICAgICAgIF90aGlzMi5ncmlkRGF0YSA9IHtcbiAgICAgICAgICAgICAgICAgICAgZGF0YTogbmV3VmFsdWVbMV0uZGF0YVswXS5kYXRhLFxuICAgICAgICAgICAgICAgICAgICBncmlkQ29uZmlnOiBuZXdWYWx1ZVsxXS5kYXRhWzBdLmNvbHVtbnNcbiAgICAgICAgICAgICAgICB9O1xuXG4gICAgICAgICAgICAgICAgX3RoaXMyLnRyZWVEYXRhID0ge1xuICAgICAgICAgICAgICAgICAgICBkYXRhOiBuZXdWYWx1ZVswXS5kYXRhXG4gICAgICAgICAgICAgICAgfTtcblxuICAgICAgICAgICAgICAgIGlmIChfdGhpczIuc3RhdGUuZ3JpZFZhbHVlICE9PSBuZXdWYWx1ZVsxXS5sYXN0RG9jSWQpIHtcbiAgICAgICAgICAgICAgICAgICAgc2VsZi5zZXRTdGF0ZSh7IGdyaWRWYWx1ZTogbmV3VmFsdWVbMV0ubGFzdERvY0lkIH0pO1xuICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgIHNlbGYuZm9yY2VVcGRhdGUoKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgLy8g0YHQvtC30LTQsNC10Lwg0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0L3QsCDQuNC30LzQtdC90LXQvdC40LUg0YHRgtGA0L7QutC4INCz0YDQuNC00LBcbiAgICAgICAgICAgIGRvY3NTdG9yZS5vbignY2hhbmdlOmRvY3NHcmlkJywgZnVuY3Rpb24gKG5ld1ZhbHVlLCBwcmV2aW91c1ZhbHVlKSB7XG4gICAgICAgICAgICAgICAgLy8g0LTQsNC90L3Ri9C1INC40LfQvNC10L3QuNC70LjRgdGMLCDQvNC10L3Rj9C10Lwg0YHQvtGB0YLQvtGP0L3QuNC1XG4gICAgICAgICAgICAgICAgc2VsZi5zZXRTdGF0ZSh7IGdyaWRWYWx1ZTogbmV3VmFsdWUgfSk7XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgLy8g0YHQvtC30LTQsNC10Lwg0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0L3QsCDQuNC30LzQtdC90LXQvdC40LUg0YHRgtGA0L7QutC4INCz0YDQuNC00LBcbiAgICAgICAgICAgIGRvY3NTdG9yZS5vbignY2hhbmdlOmRvY3NMaXN0JywgZnVuY3Rpb24gKG5ld1ZhbHVlLCBwcmV2aW91c1ZhbHVlKSB7XG4gICAgICAgICAgICAgICAgLy8g0LTQsNC90L3Ri9C1INC40LfQvNC10L3QuNC70LjRgdGMLCDQvNC10L3Rj9C10Lwg0YHQvtGB0YLQvtGP0L3QuNC1XG4gICAgICAgICAgICAgICAgc2VsZi5zZXRTdGF0ZSh7IHRyZWVWYWx1ZTogbmV3VmFsdWUgfSk7XG4gICAgICAgICAgICB9KTtcblxuICAgICAgICAgICAgLy8g0YHQvtC30LTQsNC10Lwg0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0YHQuNGB0YLQtdC80L3Ri9C5INC40LfQstC10YnQtdC90LjQtVxuICAgICAgICAgICAgZG9jc1N0b3JlLm9uKCdjaGFuZ2U6c3lzdGVtTWVzc2FnZScsIGZ1bmN0aW9uIChuZXdWYWx1ZSwgcHJldmlvdXNWYWx1ZSkge1xuICAgICAgICAgICAgICAgIC8vINC00LDQvdC90YvQtSDQuNC30LzQtdC90LjQu9C40YHRjCwg0LzQtdC90Y/QtdC8INGB0L7RgdGC0L7Rj9C90LjQtVxuICAgICAgICAgICAgICAgIHNlbGYuc2V0U3RhdGUoeyBzaG93U3lzdGVtTWVzc2FnZTogISFuZXdWYWx1ZSB9KTtcbiAgICAgICAgICAgIH0pO1xuXG4gICAgICAgICAgICAvLyDQv9C+0LrQsNC20LXQvCDQtNCw0L3QvdGL0LVcblxuICAgICAgICAgICAgLy8gICAgICAgIGxldCBsYXN0Q29tcG9uZW50ID0gbG9jYWxTdG9yYWdlWydkb2NzTGlzdCddO1xuICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignZGF0YUNoYW5nZScsIHRoaXMucHJvcHMuY29tcG9uZW50cyk7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDRgdC90LjQvNC10YIg0LLRgdC1INC/0L7QtNC/0LjRgdC60LhcclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnY29tcG9uZW50Q2xlYW51cCcsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBjb21wb25lbnRDbGVhbnVwKCkge1xuICAgICAgICAgICAgZG9jc1N0b3JlLm9mZignY2hhbmdlOnNxbFdoZXJlJyk7XG4gICAgICAgICAgICBkb2NzU3RvcmUub2ZmKCdjaGFuZ2U6c3lzdGVtTWVzc2FnZScpO1xuICAgICAgICAgICAgZG9jc1N0b3JlLm9mZignY2hhbmdlOmRvY3NMaXN0Jyk7XG4gICAgICAgICAgICBkb2NzU3RvcmUub2ZmKCdjaGFuZ2U6ZG9jc0dyaWQnKTtcbiAgICAgICAgICAgIGRvY3NTdG9yZS5vZmYoJ2NoYW5nZTpkYXRhJyk7XG4gICAgICAgICAgICBkb2NzU3RvcmUub2ZmKCdjaGFuZ2U6c3FsV2hlcmUnKTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHZhciBzeXN0ZW1NZXNzYWdlID0gZG9jc1N0b3JlLnN5c3RlbU1lc3NhZ2U7XG5cbiAgICAgICAgICAgIHRoaXMuZ2V0RmlsdGVyRmllbGRzKCk7XG5cbiAgICAgICAgICAgIHZhciBidG5QYXJhbXMgPSB7XG4gICAgICAgICAgICAgICAgYnRuU3RhcnQ6IHtcbiAgICAgICAgICAgICAgICAgICAgc2hvdzogZmFsc2VcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIGJ0bkxvZ2luOiB7XG4gICAgICAgICAgICAgICAgICAgIHNob3c6IHRydWVcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9O1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IHJlZjogJ3BhcmVudERpdicgfSxcbiAgICAgICAgICAgICAgICBNZW51VG9vbEJhcihidG5QYXJhbXMsIHRoaXMucHJvcHMudXNlckRhdGEpLFxuICAgICAgICAgICAgICAgIHRoaXMucmVuZGVyRmlsdGVyVG9vbGJhcigpLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ2RvY0NvbnRhaW5lcicsIHN0eWxlOiBzdHlsZXMuY29udGFpbmVyIH0sXG4gICAgICAgICAgICAgICAgICAgIHRoaXMucmVuZGVyRG9jVG9vbEJhcigpLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMud3JhcHBlciB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBTaWRlYmFyLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgd2lkdGg6ICczMCUnLCB0b29sYmFyOiB0cnVlLCByZWY6ICdsaXN0LXNpZGViYXInIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChUcmVlTGlzdCwgeyByZWY6ICd0cmVlTGlzdCcsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHRoaXMudHJlZURhdGFbJ2RhdGEnXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbmFtZTogJ2RvY3NMaXN0JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYmluZERhdGFGaWVsZDogJ2tvb2QnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogdGhpcy5zdGF0ZS50cmVlVmFsdWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uQ2xpY2tBY3Rpb246IHRoaXMuY2xpY2tIYW5kbGVyLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNoYW5nZUFjdGlvbjogJ2RvY3NMaXN0Q2hhbmdlJ1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0pXG4gICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB7IHN0eWxlOiBzdHlsZXMuY29udGFpbmVyIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy5yZW5kZXJBcnVhbm5lUGFnZSgpLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFNpZGViYXIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHsgdG9vbGJhcjogZmFsc2UsIHJlZjogJ2dyaWQtc2lkZWJhcicsIGhlaWdodDogJzQwMHB4JyB9LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KERhdGFHcmlkLCB7IHJlZjogJ2RhdGFHcmlkJyxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGdyaWREYXRhOiB0aGlzLmdyaWREYXRhWydkYXRhJ10sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBncmlkQ29sdW1uczogdGhpcy5ncmlkRGF0YVsnZ3JpZENvbmZpZyddLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25DaGFuZ2VBY3Rpb246ICdkb2NzR3JpZENoYW5nZScsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvbkNsaWNrOiB0aGlzLmNsaWNrSGFuZGxlcixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9uRGJsQ2xpY2s6IHRoaXMuZGJsQ2xpY2tIYW5kbGVyLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb25IZWFkZXJDbGljazogdGhpcy5oZWFkZXJDbGlja0hhbmRsZXIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWx1ZTogdGhpcy5zdGF0ZS5ncmlkVmFsdWUsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB1cmw6ICdhcGknIH0pLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgTW9kYWxQYWdlLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgeyByZWY6ICdtb2RhbHBhZ2VGaWx0ZXInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGFsUGFnZUJ0bkNsaWNrOiB0aGlzLm1vZGFsUGFnZUJ0bkNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1vZGFsUGFnZU5hbWU6ICdGaWx0ZXInLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNob3c6IHRoaXMuc3RhdGUuZ2V0RmlsdGVyIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEdyaWRGaWx0ZXIsIHsgcmVmOiAnZ3JpZEZpbHRlcicsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZ3JpZENvbmZpZzogdGhpcy5ncmlkRGF0YVsnZ3JpZENvbmZpZyddLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE6IHRoaXMuZmlsdGVyRGF0YSB9KVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KE1vZGFsUGFnZURlbGV0ZSwgeyByZWY6ICdtb2RhbHBhZ2VEZWxldGUnLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kYWxQYWdlQnRuQ2xpY2s6IHRoaXMubW9kYWxQYWdlRGVsQnRuQ2xpY2ssXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzaG93OiB0aGlzLnN0YXRlLmdldERlbGV0ZU1vZGFsUGFnZSB9KSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChNb2RhbFBhZ2VJbmZvLCB7IHJlZjogJ21vZGFscGFnZUluZm8nLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgbW9kYWxQYWdlQnRuQ2xpY2s6IHRoaXMubW9kYWxQYWdlSW5mb0J0bkNsaWNrLFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc2hvdzogdGhpcy5zdGF0ZS5zaG93U3lzdGVtTWVzc2FnZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN5c3RlbU1lc3NhZ2U6IHN5c3RlbU1lc3NhZ2UgfSlcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0JLQtdGA0L3QtdGCINC60L7QvNC/0L7QvdC10L3RgiDQntGC0YfQtdGCLCDQtdGB0LvQuCDQstGL0LHRgNCw0L3QvdCw0Y8g0LLQtdGC0LrQsCDRgdC+0LTQtdGA0LbQuNGCINGC0LjQvyA9PSBhcnVhbm5lXHJcbiAgICAgICAgICogQHJldHVybnMge2Jvb2xlYW58WE1MfVxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdyZW5kZXJBcnVhbm5lUGFnZScsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJBcnVhbm5lUGFnZSgpIHtcbiAgICAgICAgICAgIHZhciBpc1JlcG9ydCA9IHRoaXMuaXNSZXBvcnRzKHRoaXMuc3RhdGUudHJlZVZhbHVlKTtcbiAgICAgICAgICAgIHZhciBDb21wb25lbnQgPSBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgIFNpZGViYXIsXG4gICAgICAgICAgICAgICAgeyB0b29sYmFyOiB0cnVlLCByZWY6ICdhcnVhbm5lLXNpZGViYXInLCBoZWlnaHQ6ICcxMDAlJyB9LFxuICAgICAgICAgICAgICAgICdBcnVhbm5lJ1xuICAgICAgICAgICAgKTtcbiAgICAgICAgICAgIHJldHVybiBpc1JlcG9ydCAmJiBDb21wb25lbnQ7XG4gICAgICAgIH1cblxuICAgICAgICAvKipcclxuICAgICAgICAgKiDQktC10YDQvdC10YIg0LrQvtC80L/QvtC90LXRgiAtINC/0LDQvdC10LvRjCDQuNC90YHRgtGA0YPQvNC10L3RgtC+0LIg0LTQvtC60YPQvNC10L3RgtCwXHJcbiAgICAgICAgICogQHJldHVybnMge1hNTH1cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyRG9jVG9vbEJhcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJEb2NUb29sQmFyKCkge1xuICAgICAgICAgICAgdmFyIHRvb2xiYXJQYXJhbXMgPSB0aGlzLnByZXBhcmVQYXJhbXNGb3JUb29sYmFyKCk7IC8v0L/QsNGA0LDQvNC10YLRgNGLINC00LvRjyDQutC90L7Qv9C+0Log0YPQv9GA0LDQstC70LXQvdC40Y8sINCy0LfQsNCy0LjRgdC40LzQvtGB0YLQuCDQvtGCINCw0LrRgtC40LLQvdC+0Lkg0YHRgtGA0L7QutC4XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgIFRvb2xiYXJDb250YWluZXIsXG4gICAgICAgICAgICAgICAgeyByZWY6ICd0b29sYmFyQ29udGFpbmVyJyB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KEJ0bkFkZCwgeyBvbkNsaWNrOiB0aGlzLmJ0bkFkZENsaWNrLCBzaG93OiB0b29sYmFyUGFyYW1zWydidG5BZGQnXS5zaG93LFxuICAgICAgICAgICAgICAgICAgICAgICAgZGlzYWJsZTogdG9vbGJhclBhcmFtc1snYnRuQWRkJ10uZGlzYWJsZWQgfSksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQnRuRWRpdCwgeyBvbkNsaWNrOiB0aGlzLmJ0bkVkaXRDbGljaywgc2hvdzogdG9vbGJhclBhcmFtc1snYnRuRWRpdCddLnNob3csXG4gICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlOiB0b29sYmFyUGFyYW1zWydidG5FZGl0J10uZGlzYWJsZWQgfSksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQnRuRGVsZXRlLCB7IG9uQ2xpY2s6IHRoaXMuYnRuRGVsZXRlQ2xpY2ssIHNob3c6IHRvb2xiYXJQYXJhbXNbJ2J0bkRlbGV0ZSddLnNob3csXG4gICAgICAgICAgICAgICAgICAgICAgICBkaXNhYmxlOiB0b29sYmFyUGFyYW1zWydidG5EZWxldGUnXS5kaXNhYmxlZCB9KSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChCdG5QcmludCwgeyBvbkNsaWNrOiB0aGlzLmJ0blByaW50Q2xpY2ssIHNob3c6IHRvb2xiYXJQYXJhbXNbJ2J0blByaW50J10uc2hvdyxcbiAgICAgICAgICAgICAgICAgICAgICAgIGRpc2FibGU6IHRvb2xiYXJQYXJhbXNbJ2J0blByaW50J10uZGlzYWJsZWQgfSksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoQnRuRmlsdGVyLCB7IG9uQ2xpY2s6IHRoaXMuYnRuRmlsdGVyQ2xpY2sgfSlcbiAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0JLQtdGA0L3QtdGCINC60L7QvNC/0L7QvdC10YIg0YEg0LTQsNC90L3Ri9C80Lgg0YHRgtGA0L7QutC4INGE0LjQu9GM0YLRgNCw0YbQuNC4XHJcbiAgICAgICAgICogQHJldHVybnMge1hNTH1cclxuICAgICAgICAgKi9cblxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyRmlsdGVyVG9vbGJhcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXJGaWx0ZXJUb29sYmFyKCkge1xuICAgICAgICAgICAgdmFyIGZpbHRlciA9IHRoaXMuZ2V0RmlsdGVyU3RyaW5nKCk7XG4gICAgICAgICAgICB2YXIgY29tcG9uZW50ID0gdm9pZCAwO1xuXG4gICAgICAgICAgICBpZiAoZmlsdGVyKSB7XG4gICAgICAgICAgICAgICAgY29tcG9uZW50ID0gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgVG9vbGJhckNvbnRhaW5lcixcbiAgICAgICAgICAgICAgICAgICAgeyByZWY6ICdmaWx0ZXJUb29sYmFyQ29udGFpbmVyJywgcG9zaXRpb246ICdsZWZ0JyB9LFxuICAgICAgICAgICAgICAgICAgICBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgICAgICAgICAgJ3NwYW4nLFxuICAgICAgICAgICAgICAgICAgICAgICAgbnVsbCxcbiAgICAgICAgICAgICAgICAgICAgICAgICcgRmlsdGVyOiAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy5nZXRGaWx0ZXJTdHJpbmcoKVxuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgcmV0dXJuIGNvbXBvbmVudDtcbiAgICAgICAgfVxuXG4gICAgICAgIC8qKlxyXG4gICAgICAgICAqINCf0YDQvtCw0L3QsNC70LjQt9C40YDRg9C10YIg0YHQstC+0LnRgdGC0LLQsCDQstGL0LHRgNCw0L3QvdC+0LPQviDQtNC+0LrRg9C80LXQvdGC0LAg0Lgg0LLQtdGA0L3QtdGCIHRydWUgLCDQtdGB0LvQuCDRgtC40L8gPT0gQXJ1YW5uZVxyXG4gICAgICAgICAqIEBwYXJhbSBkb2N1bWVudFxyXG4gICAgICAgICAqIEByZXR1cm5zIHtib29sZWFufVxyXG4gICAgICAgICAqL1xuXG4gICAgfSwge1xuICAgICAgICBrZXk6ICdpc1JlcG9ydHMnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaXNSZXBvcnRzKGRvY3VtZW50KSB7XG4gICAgICAgICAgICB2YXIgZGF0YSA9IHRoaXMuZmluZENvbXBvbmVudCgnZG9jc0xpc3QnKVswXS5kYXRhLFxuICAgICAgICAgICAgICAgIGRvY3VtZW50RGF0YSA9IGRhdGEuZmlsdGVyKGZ1bmN0aW9uIChyb3cpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gcm93Lmtvb2QgPT09IGRvY3VtZW50ICYmIHJvdy5wcm9wcyAmJiBKU09OLnBhcnNlKHJvdy5wcm9wcykudHlwZSA9PT0gJ2FydWFubmUnO1xuICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgIHJldHVybiAhIWRvY3VtZW50RGF0YS5sZW5ndGg7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2ZpbmRDb21wb25lbnQnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gZmluZENvbXBvbmVudChjb21wb25lbnROYW1lKSB7XG4gICAgICAgICAgICAvLyDQstC10YDQvdC10YIg0LTQsNC90L3Ri9C1INC60L7QvNC/0L7QvdC10L3RgtCwINC/0L4g0LXQs9C+INC90LDQt9Cy0LDQvdC40Y5cbiAgICAgICAgICAgIHZhciBjb21wb25lbnREYXRhID0gW107XG5cbiAgICAgICAgICAgIGlmICh0aGlzLnByb3BzLmNvbXBvbmVudHMubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgICAgIGNvbXBvbmVudERhdGEgPSB0aGlzLnByb3BzLmNvbXBvbmVudHMuZmlsdGVyKGZ1bmN0aW9uIChpdGVtKSB7XG4gICAgICAgICAgICAgICAgICAgIGlmIChpdGVtLm5hbWUgPT0gY29tcG9uZW50TmFtZSkge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIGl0ZW07XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgaWYgKCFjb21wb25lbnREYXRhWzBdLm5hbWUgPT0gJ2RvY3NHcmlkJyAmJiBjb21wb25lbnREYXRhWzBdLmxhc3REb2NJZCA9PSAnMCcgJiYgIWZsdXguc3RvcmVzLmRvY3NTdG9yZS5kb2NzR3JpZCkge1xuICAgICAgICAgICAgICAgIGNvbXBvbmVudERhdGFbMF0ubGFzdERvY2lkID0gY29tcG9uZW50RGF0YVswXS5kYXRhWzBdLmlkIHx8IDA7XG4gICAgICAgICAgICAgICAgLy8g0YHQvtGF0YDQsNC90LjQvCDQvdC+0LzQtdGAINCyINGB0YLQvtGA0LVcbiAgICAgICAgICAgICAgICBmbHV4LmRvQWN0aW9uKCdkb2NzR3JpZENoYW5nZScsIGNvbXBvbmVudERhdGFbMF0uZGF0YVswXS5pZCB8fCAwKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgcmV0dXJuIGNvbXBvbmVudERhdGE7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2J0bkZpbHRlckNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGJ0bkZpbHRlckNsaWNrKCkge1xuICAgICAgICAgICAgLy8g0L7RgtC60YDQvtC10YIg0LzQvtC00LDQu9GM0L3QvtC1INC+0LrQvdC+INGBINC/0L7Qu9GP0LzQuCDQtNC70Y8g0YTQuNC70YzRgtGA0LDRhtC40LhcbiAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyBnZXRGaWx0ZXI6IHRydWUgfSk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2J0bkRlbGV0ZUNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGJ0bkRlbGV0ZUNsaWNrKCkge1xuICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IGdldERlbGV0ZU1vZGFsUGFnZTogdHJ1ZSB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnYnRuQWRkQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gYnRuQWRkQ2xpY2soKSB7XG4gICAgICAgICAgICAvLyDQvtCx0YDQsNCx0L7RgtGH0LjQuiDRgdC+0LHRi9GC0LjRjyDQutC70LjQuiDQutC90L7Qv9C60LggXCLQlNC+0LHQsNCy0LjRgtGMXCJcbiAgICAgICAgICAgIC8vINCy0YvQt9C+0LLQtdC8INC00LXQudGB0YLQstC40Y8g0L3QsCDRhNC70LDQutGB0LVcbiAgICAgICAgICAgIGZsdXguZG9BY3Rpb24oJ0FkZCcpO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdidG5FZGl0Q2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gYnRuRWRpdENsaWNrKCkge1xuICAgICAgICAgICAgLy8g0L7QsdGA0LDQsdC+0YLRh9C40Log0YHQvtCx0YvRgtC40Y8g0LrQu9C40Log0LrQvdC+0L/QutC4IFwi0JjQt9C80LXQvdC40YLRjFwiXG4gICAgICAgICAgICAvLyDQstGL0LfQvtCy0LXQvCDQtNC10LnRgdGC0LLQuNGPINC90LAg0YTQu9Cw0LrRgdC1XG4gICAgICAgICAgICBmbHV4LmRvQWN0aW9uKCdFZGl0Jyk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2J0blByaW50Q2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gYnRuUHJpbnRDbGljaygpIHtcbiAgICAgICAgICAgIC8vINC+0LHRgNCw0LHQvtGC0YfQuNC6INGB0L7QsdGL0YLQuNGPINC60LvQuNC6INC60L3QvtC/0LrQuCBcItCY0LfQvNC10L3QuNGC0YxcIlxuICAgICAgICAgICAgLy8g0LLRi9C30L7QstC10Lwg0LTQtdC50YHRgtCy0LjRjyDQvdCwINGE0LvQsNC60YHQtVxuICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignUHJpbnQnKTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnY2xpY2tIYW5kbGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGNsaWNrSGFuZGxlcihhY3Rpb24sIGlkKSB7XG4gICAgICAgICAgICAvLyDRgdC+0YXRgNCw0L3QuNC8INCyINGF0YDQsNC90LjQu9C40YnQtVxuICAgICAgICAgICAgaWYgKGFjdGlvbiAmJiBpZCkge1xuICAgICAgICAgICAgICAgIGZsdXguZG9BY3Rpb24oYWN0aW9uLCBpZCk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBpZiAoYWN0aW9uID09ICdkb2NzR3JpZENoYW5nZScpIHtcbiAgICAgICAgICAgICAgICB0aGlzLmdyaWREYXRhLnZhbHVlID0gaWQ7XG4gICAgICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IGdyaWRWYWx1ZTogaWQgfSk7XG4gICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgIHRoaXMudHJlZURhdGEudmFsdWUgPSBpZDtcbiAgICAgICAgICAgICAgICB0aGlzLnNldFN0YXRlKHsgdHJlZVZhbHVlOiBpZCB9KTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnZGJsQ2xpY2tIYW5kbGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIGRibENsaWNrSGFuZGxlcigpIHtcbiAgICAgICAgICAgIC8vINCy0YvQt9C+0LLQtdGCINC80LXRgtC+0LQg0YDQtdC00LDQutGC0LjRgNC+0LLQsNC90LjRj1xuICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignRWRpdCcpO1xuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdoZWFkZXJDbGlja0hhbmRsZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gaGVhZGVyQ2xpY2tIYW5kbGVyKHNvcnRCeSkge1xuICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignc29ydEJ5Q2hhbmdlJywgc29ydEJ5KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAnbW9kYWxQYWdlQnRuQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gbW9kYWxQYWdlQnRuQ2xpY2soYnRuRXZlbnQpIHtcbiAgICAgICAgICAgIC8vINC+0LHRgNCw0LHQvtGC0YfQuNC6INC00LvRjyDQutC90L7Qv9C60Lgg0YTQuNC70YzRgtGA0LDRhtC40LhcbiAgICAgICAgICAgIHZhciBmaWx0ZXJTdHJpbmcgPSAnJztcbiAgICAgICAgICAgIGlmIChidG5FdmVudCA9PSAnT2snKSB7XG4gICAgICAgICAgICAgICAgLy8g0YHQvtCx0LjRgNCw0LXQvCDQtNCw0L3QvdGL0LVcbiAgICAgICAgICAgICAgICB2YXIgZ3JpZEZpbHRlciA9IHRoaXMucmVmc1snZ3JpZEZpbHRlciddLFxuICAgICAgICAgICAgICAgICAgICBmaWx0ZXJEYXRhID0gZ3JpZEZpbHRlci5zdGF0ZS5kYXRhO1xuXG4gICAgICAgICAgICAgICAgdGhpcy5maWx0ZXJEYXRhID0gZmlsdGVyRGF0YS5tYXAoZnVuY3Rpb24gKHJvdykge1xuICAgICAgICAgICAgICAgICAgICBpZiAocm93LnZhbHVlKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBmaWx0ZXJTdHJpbmcgPSBmaWx0ZXJTdHJpbmcgKyAoZmlsdGVyU3RyaW5nLmxlbmd0aCA+IDAgPyBcIiBhbmQgXCIgOiBcIiB3aGVyZSBcIik7XG4gICAgICAgICAgICAgICAgICAgICAgICBzd2l0Y2ggKHJvdy50eXBlKSB7XG5cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjYXNlICd0ZXh0JzpcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZmlsdGVyU3RyaW5nID0gZmlsdGVyU3RyaW5nICsgcm93LnJlZnMgKyBcIiBpbGlrZSAnJVwiICsgcm93LnZhbHVlICsgXCIlJ1wiO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjYXNlICdzdHJpbmcnOlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBmaWx0ZXJTdHJpbmcgPSBmaWx0ZXJTdHJpbmcgKyByb3cucmVmcyArIFwiIGlsaWtlICdcIiArIHJvdy52YWx1ZSArIFwiJSdcIjtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY2FzZSAnZGF0ZSc6XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZpbHRlclN0cmluZyA9IGZpbHRlclN0cmluZyArIHJvdy5yZWZzICsgXCIgPSAnXCIgKyByb3cudmFsdWUgKyBcIidcIjtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY2FzZSAnbnVtYmVyJzpcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZmlsdGVyU3RyaW5nID0gZmlsdGVyU3RyaW5nICsgcm93LnJlZnMgKyBcIiA9IFwiICsgcm93LnZhbHVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjYXNlICdpbnRlZ2VyJzpcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZmlsdGVyU3RyaW5nID0gZmlsdGVyU3RyaW5nICsgcm93LnJlZnMgKyBcIiA9IFwiICsgcm93LnZhbHVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICByZXR1cm4gcm93O1xuICAgICAgICAgICAgICAgIH0sIHRoaXMpO1xuICAgICAgICAgICAgICAgIC8vINC/0YDQuNC80LXQvdC10Lwg0YTQuNC70YzRgtGAXG4gICAgICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignc3FsV2hlcmVDaGFuZ2UnLCBmaWx0ZXJTdHJpbmcpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IGdldEZpbHRlcjogZmFsc2UgfSk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ21vZGFsUGFnZURlbEJ0bkNsaWNrJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIG1vZGFsUGFnZURlbEJ0bkNsaWNrKGJ0bkV2ZW50KSB7XG4gICAgICAgICAgICAvLyDQvtCx0YDQsNCx0L7RgtGH0LjQuiDQstGL0LfQvtCy0LAg0LzQvtC00LDQu9GM0L3QvtCz0L4g0L7QutC90LAg0YPQtNCw0LvQtdC90LjRj1xuICAgICAgICAgICAgdGhpcy5zZXRTdGF0ZSh7IGdldERlbGV0ZU1vZGFsUGFnZTogZmFsc2UgfSk7XG5cbiAgICAgICAgICAgIGlmIChidG5FdmVudCA9PSAnT2snKSB7XG4gICAgICAgICAgICAgICAgLy8g0LLRi9C30L7QstC10Lwg0LTQtdC50YHRgtCy0LjRjyDQvdCwINGE0LvQsNC60YHQtVxuICAgICAgICAgICAgICAgIGZsdXguZG9BY3Rpb24oJ0RlbGV0ZScpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfSwge1xuICAgICAgICBrZXk6ICdtb2RhbFBhZ2VJbmZvQnRuQ2xpY2snLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gbW9kYWxQYWdlSW5mb0J0bkNsaWNrKCkge1xuXG4gICAgICAgICAgICAvLyDQvtCx0YDQsNCx0L7RgtGH0LjQuiDQstGL0LfQvtCy0LAg0LzQvtC00LDQu9GM0L3QvtCz0L4g0L7QutC90LAg0YHQuNGB0YLQtdC80L3QvtCz0L4g0YHQvtC+0LHRidC10L3QuNGPXG4gICAgICAgICAgICB0aGlzLnNldFN0YXRlKHsgc2hvd1N5c3RlbU1lc3NhZ2U6IGZhbHNlIH0pO1xuICAgICAgICAgICAgLy8g0LLRi9C30L7QstC10Lwg0LTQtdC50YHRgtCy0LjRjyDQvdCwINGE0LvQsNC60YHQtVxuICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignc3lzdGVtTWVzc2FnZUNoYW5nZScsIG51bGwpO1xuICAgICAgICB9XG5cbiAgICAgICAgLyoqXHJcbiAgICAgICAgICog0YHQvtC30LTQsNGB0YIg0LjQtyDQv9C+0Lt00Lkg0LPRgNC40LTQsCDQutC+0LzQv9C+0L3QtdC90YLRiyDQtNC70Y8g0YTQvtGA0LzQuNGA0L7QstCw0L3QuNGPINGD0YHQu9C+0LLQuNC5INGE0LjQu9GM0YLRgNCw0YbQuNC4XHJcbiAgICAgICAgICogQHJldHVybnMge0FycmF5fCp9XHJcbiAgICAgICAgICovXG5cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2dldEZpbHRlckZpZWxkcycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBnZXRGaWx0ZXJGaWVsZHMoKSB7XG4gICAgICAgICAgICB2YXIgX3RoaXMzID0gdGhpcztcblxuICAgICAgICAgICAgdmFyIGdyaWRDb21wb25lbnRzID0gZG9jc1N0b3JlLmRhdGEsXG4gICAgICAgICAgICAgICAgZ3JpZERhdGEgPSBbXSxcbiAgICAgICAgICAgICAgICBwcmV2aW9zRmlsdGVyID0gdGhpcy5maWx0ZXJEYXRhO1xuXG4gICAgICAgICAgICBmb3IgKHZhciBpID0gMDsgaSA8IGdyaWRDb21wb25lbnRzLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgICAgICAgaWYgKGdyaWRDb21wb25lbnRzW2ldWyduYW1lJ10gPT0gJ2RvY3NHcmlkJykge1xuICAgICAgICAgICAgICAgICAgICAvLyDQuNGJ0LXQvCDQv9C+0LvQtSBjb2x1bW5zXG4gICAgICAgICAgICAgICAgICAgIGZvciAodmFyIGZpZWxkIGluIGdyaWRDb21wb25lbnRzW2ldLmRhdGFbMF0pIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChmaWVsZCA9PSAnY29sdW1ucycpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBncmlkRGF0YSA9IGdyaWRDb21wb25lbnRzW2ldLmRhdGFbMF0uY29sdW1ucztcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIGlmIChncmlkRGF0YSkge1xuICAgICAgICAgICAgICAgIHRoaXMuZmlsdGVyRGF0YSA9IFtdOyAvLyDQvtCx0L3Rg9C70LjQvCDQvNCw0YHRgdC40LJcblxuICAgICAgICAgICAgICAgIGdyaWREYXRhLm1hcChmdW5jdGlvbiAocm93KSB7XG4gICAgICAgICAgICAgICAgICAgIHZhciBjb21wb25lbnRUeXBlID0gJ3RleHQnLFxuICAgICAgICAgICAgICAgICAgICAgICAgY29tcG9uZW50T2JqZWt0VmFsdWUgPSB2b2lkIDA7XG5cbiAgICAgICAgICAgICAgICAgICAgZm9yICh2YXIgX2kgPSAwOyBfaSA8IHByZXZpb3NGaWx0ZXIubGVuZ3RoOyBfaSsrKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAvLyDQuNGJ0LXQvCBcItGB0YLQsNGA0L7QtVwiINC30L3QsNGH0LXQvdC40LUg0YTQuNC70YzRgtGA0LAg0Lgg0LXRgdC70Lgg0LXRgdGC0YwsINGC0L4g0L7RgtC00LDQtdC8INC10LPQviB2YWx1ZVxuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHByZXZpb3NGaWx0ZXJbX2ldLnJlZnMgPT0gcm93LmlkKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29tcG9uZW50T2JqZWt0VmFsdWUgPSBwcmV2aW9zRmlsdGVyW19pXS52YWx1ZTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAgICAgICAgIGlmIChyb3cudHlwZSkge1xuICAgICAgICAgICAgICAgICAgICAgICAgY29tcG9uZW50VHlwZSA9IHJvdy50eXBlO1xuICAgICAgICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgICAgICAgICAgLy8g0YHQvtCx0LXRgNC10Lwg0LzQsNGB0YHQuNCyINC+0LHRitC10LrRgtC+0LJcbiAgICAgICAgICAgICAgICAgICAgX3RoaXMzLmZpbHRlckRhdGEucHVzaCh7XG4gICAgICAgICAgICAgICAgICAgICAgICBuYW1lOiByb3cubmFtZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiBjb21wb25lbnRPYmpla3RWYWx1ZSB8fCBudWxsLFxuICAgICAgICAgICAgICAgICAgICAgICAgdHlwZTogY29tcG9uZW50VHlwZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZnM6IHJvdy5pZFxuICAgICAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybiB0aGlzLmZpbHRlckRhdGE7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ2dldEZpbHRlclN0cmluZycsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiBnZXRGaWx0ZXJTdHJpbmcoKSB7XG4gICAgICAgICAgICAvLyDQv9GA0LXQvtCx0YDQsNC30YPQtdGCINC00LDQvdC90YvQtSDRhNC40LvRgtGA0LAg0LIg0YHRgtGA0L7QutGDXG4gICAgICAgICAgICB2YXIgc3RyaW5nID0gJyc7XG5cbiAgICAgICAgICAgIHRoaXMuZmlsdGVyRGF0YS5tYXAoZnVuY3Rpb24gKHJvdykge1xuICAgICAgICAgICAgICAgIGlmIChyb3cudmFsdWUpIHtcbiAgICAgICAgICAgICAgICAgICAgc3RyaW5nID0gc3RyaW5nICsgcm93Lm5hbWUgKyAnOicgKyByb3cudmFsdWUgKyAnOyAnO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgcmV0dXJuIHN0cmluZztcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncHJlcGFyZVBhcmFtc0ZvclRvb2xiYXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gcHJlcGFyZVBhcmFtc0ZvclRvb2xiYXIoKSB7XG4gICAgICAgICAgICB2YXIgX3RoaXM0ID0gdGhpcztcblxuICAgICAgICAgICAgLy8g0YfQuNGC0LDQtdC8INC00LDQvdC90YvQtSDRgdC+INGB0YLQvtGA0LAsINGE0L7RgNC80LjRgNGD0LXQvCDQv9Cw0YDQsNC80LXRgtGA0Ysg0LTQu9GPINC60L3QvtC/0L7QuiDRg9C/0YDQsNCy0LvQtdC90LjRjywg0Lgg0YLRg9C00LAg0LjRhSDQvtGC0LTQsNC10LxcbiAgICAgICAgICAgIC8vZG9jc0dyaWRDaGFuZ2UgKGZsdXguc3RvcmVzLmRvY3NTdG9yZS4pXG4gICAgICAgICAgICB2YXIgZ3JpZCA9IHRoaXMuZmluZENvbXBvbmVudCgnZG9jc0dyaWQnKSB8fCBbXSxcbiAgICAgICAgICAgICAgICBsYXN0Um93SWQgPSB0aGlzLnN0YXRlLmFjdGl2Um93SWQsXG4gICAgICAgICAgICAgICAgZGF0YSA9IFtdLFxuICAgICAgICAgICAgICAgIGRhdGFSb3cgPSBbXSxcbiAgICAgICAgICAgICAgICB0b29sYmFyUGFyYW1zID0ge1xuICAgICAgICAgICAgICAgIGJ0bkFkZDoge1xuICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIGJ0bkVkaXQ6IHtcbiAgICAgICAgICAgICAgICAgICAgc2hvdzogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBidG5EZWxldGU6IHtcbiAgICAgICAgICAgICAgICAgICAgc2hvdzogdHJ1ZSxcbiAgICAgICAgICAgICAgICAgICAgZGlzYWJsZWQ6IGZhbHNlXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBidG5QcmludDoge1xuICAgICAgICAgICAgICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICAgICAgICAgICAgICBkaXNhYmxlZDogZmFsc2VcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9O1xuXG4gICAgICAgICAgICAvLyDQv9GA0L7QstC10YDQuNC8INC90LDQu9C40YfQuNC1INC00LDQvdC90YvRhSwg0LXRgdC70Lgg0LXRgdGC0Ywg0L/RgNC+0L/QuNGF0L3QtdC8INC60L7QvNC/0L7QvdC10L3RgtCw0LxcblxuICAgICAgICAgICAgaWYgKGdyaWQubGVuZ3RoID4gMCAmJiBncmlkWzBdLmRhdGEubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgICAgIGRhdGEgPSBncmlkWzBdLmRhdGFbMF0uZGF0YTtcbiAgICAgICAgICAgICAgICBkYXRhUm93ID0gZGF0YS5maWx0ZXIoZnVuY3Rpb24gKHJvdykge1xuICAgICAgICAgICAgICAgICAgICBpZiAocm93LmlkID09PSBfdGhpczQuc3RhdGUuZ3JpZFZhbHVlKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gcm93O1xuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgIHJldHVybiB0b29sYmFyUGFyYW1zO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAoZGF0YVJvdy5sZW5ndGggPiAwICYmIGRhdGFSb3dbMF0uc3RhdHVzID09ICfQn9GA0L7QstC10LTQtdC9Jykge1xuICAgICAgICAgICAgICAgIC8vINGD0LTQsNC70Y/RgtGMINC90LXQu9GM0LfRj1xuICAgICAgICAgICAgICAgIHRvb2xiYXJQYXJhbXMuYnRuRGVsZXRlLnNob3cgPSBmYWxzZTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHJldHVybiB0b29sYmFyUGFyYW1zO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIFJlZ2lzdGVyO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuUmVnaXN0ZXIucHJvcFR5cGVzID0ge1xuICAgIGNvbXBvbmVudHM6IFByb3BUeXBlcy5hcnJheS5pc1JlcXVpcmVkXG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IFJlZ2lzdGVyO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9kb2MtcmVnaXN0ZXIvZG9jLXJlZ2lzdGVyLmpzeFxuLy8gbW9kdWxlIGlkID0gMTc2XG4vLyBtb2R1bGUgY2h1bmtzID0gNSIsIid1c2Ugc3RyaWN0JztcblxudmFyIF9jcmVhdGVDbGFzcyA9IGZ1bmN0aW9uICgpIHsgZnVuY3Rpb24gZGVmaW5lUHJvcGVydGllcyh0YXJnZXQsIHByb3BzKSB7IGZvciAodmFyIGkgPSAwOyBpIDwgcHJvcHMubGVuZ3RoOyBpKyspIHsgdmFyIGRlc2NyaXB0b3IgPSBwcm9wc1tpXTsgZGVzY3JpcHRvci5lbnVtZXJhYmxlID0gZGVzY3JpcHRvci5lbnVtZXJhYmxlIHx8IGZhbHNlOyBkZXNjcmlwdG9yLmNvbmZpZ3VyYWJsZSA9IHRydWU7IGlmIChcInZhbHVlXCIgaW4gZGVzY3JpcHRvcikgZGVzY3JpcHRvci53cml0YWJsZSA9IHRydWU7IE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0YXJnZXQsIGRlc2NyaXB0b3Iua2V5LCBkZXNjcmlwdG9yKTsgfSB9IHJldHVybiBmdW5jdGlvbiAoQ29uc3RydWN0b3IsIHByb3RvUHJvcHMsIHN0YXRpY1Byb3BzKSB7IGlmIChwcm90b1Byb3BzKSBkZWZpbmVQcm9wZXJ0aWVzKENvbnN0cnVjdG9yLnByb3RvdHlwZSwgcHJvdG9Qcm9wcyk7IGlmIChzdGF0aWNQcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvciwgc3RhdGljUHJvcHMpOyByZXR1cm4gQ29uc3RydWN0b3I7IH07IH0oKTtcblxuZnVuY3Rpb24gX2NsYXNzQ2FsbENoZWNrKGluc3RhbmNlLCBDb25zdHJ1Y3RvcikgeyBpZiAoIShpbnN0YW5jZSBpbnN0YW5jZW9mIENvbnN0cnVjdG9yKSkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiQ2Fubm90IGNhbGwgYSBjbGFzcyBhcyBhIGZ1bmN0aW9uXCIpOyB9IH1cblxuZnVuY3Rpb24gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4oc2VsZiwgY2FsbCkgeyBpZiAoIXNlbGYpIHsgdGhyb3cgbmV3IFJlZmVyZW5jZUVycm9yKFwidGhpcyBoYXNuJ3QgYmVlbiBpbml0aWFsaXNlZCAtIHN1cGVyKCkgaGFzbid0IGJlZW4gY2FsbGVkXCIpOyB9IHJldHVybiBjYWxsICYmICh0eXBlb2YgY2FsbCA9PT0gXCJvYmplY3RcIiB8fCB0eXBlb2YgY2FsbCA9PT0gXCJmdW5jdGlvblwiKSA/IGNhbGwgOiBzZWxmOyB9XG5cbmZ1bmN0aW9uIF9pbmhlcml0cyhzdWJDbGFzcywgc3VwZXJDbGFzcykgeyBpZiAodHlwZW9mIHN1cGVyQ2xhc3MgIT09IFwiZnVuY3Rpb25cIiAmJiBzdXBlckNsYXNzICE9PSBudWxsKSB7IHRocm93IG5ldyBUeXBlRXJyb3IoXCJTdXBlciBleHByZXNzaW9uIG11c3QgZWl0aGVyIGJlIG51bGwgb3IgYSBmdW5jdGlvbiwgbm90IFwiICsgdHlwZW9mIHN1cGVyQ2xhc3MpOyB9IHN1YkNsYXNzLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDbGFzcyAmJiBzdXBlckNsYXNzLnByb3RvdHlwZSwgeyBjb25zdHJ1Y3RvcjogeyB2YWx1ZTogc3ViQ2xhc3MsIGVudW1lcmFibGU6IGZhbHNlLCB3cml0YWJsZTogdHJ1ZSwgY29uZmlndXJhYmxlOiB0cnVlIH0gfSk7IGlmIChzdXBlckNsYXNzKSBPYmplY3Quc2V0UHJvdG90eXBlT2YgPyBPYmplY3Quc2V0UHJvdG90eXBlT2Yoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIDogc3ViQ2xhc3MuX19wcm90b19fID0gc3VwZXJDbGFzczsgfVxuXG52YXIgUHJvcFR5cGVzID0gcmVxdWlyZSgncHJvcC10eXBlcycpO1xuXG52YXIgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpLFxuICAgIE1vZGFsUGFnZSA9IHJlcXVpcmUoJy4uL21vZGFsUGFnZS5qc3gnKSxcbiAgICBzdHlsZXMgPSByZXF1aXJlKCcuLi9tb2RhbHBhZ2UtZGVsZXRlL21vZGFscGFnZS1kZWxldGUtc3R5bGVzJyk7XG5cbnZhciBNb2RhbFBhZ2VEZWxldGUgPSBmdW5jdGlvbiAoX1JlYWN0JFB1cmVDb21wb25lbnQpIHtcbiAgICBfaW5oZXJpdHMoTW9kYWxQYWdlRGVsZXRlLCBfUmVhY3QkUHVyZUNvbXBvbmVudCk7XG5cbiAgICBmdW5jdGlvbiBNb2RhbFBhZ2VEZWxldGUocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIE1vZGFsUGFnZURlbGV0ZSk7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKE1vZGFsUGFnZURlbGV0ZS5fX3Byb3RvX18gfHwgT2JqZWN0LmdldFByb3RvdHlwZU9mKE1vZGFsUGFnZURlbGV0ZSkpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIHNob3c6IF90aGlzLnByb3BzLnNob3dcbiAgICAgICAgfTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhNb2RhbFBhZ2VEZWxldGUsIFt7XG4gICAgICAgIGtleTogJ2NvbXBvbmVudFdpbGxSZWNlaXZlUHJvcHMnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gY29tcG9uZW50V2lsbFJlY2VpdmVQcm9wcyhuZXh0UHJvcHMpIHtcbiAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyBzaG93OiBuZXh0UHJvcHMuc2hvdyB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcbiAgICAgICAgICAgIHZhciBtb2RhbE9iamVjdHMgPSBbJ2J0bk9rJywgJ2J0bkNhbmNlbCddO1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICBNb2RhbFBhZ2UsXG4gICAgICAgICAgICAgICAgeyByZWY6ICdtb2RhbFBhZ2UnLFxuICAgICAgICAgICAgICAgICAgICBtb2RhbFBhZ2VCdG5DbGljazogdGhpcy5wcm9wcy5tb2RhbFBhZ2VCdG5DbGljayxcbiAgICAgICAgICAgICAgICAgICAgc2hvdzogdGhpcy5zdGF0ZS5zaG93LFxuICAgICAgICAgICAgICAgICAgICBtb2RhbFBhZ2VOYW1lOiAnRGVsZXRlIGRvY3VtZW50JyB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ2NvbnRhaW5lcicgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudCgnaW1nJywgeyByZWY6ICdpbWFnZScsIHNyYzogc3R5bGVzLmljb24gfSksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnc3BhbicsXG4gICAgICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ21lc3NhZ2UnIH0sXG4gICAgICAgICAgICAgICAgICAgICAgICAnIFxcdTA0MjNcXHUwNDM0XFx1MDQzMFxcdTA0M0JcXHUwNDM4XFx1MDQ0MlxcdTA0NEMgXFx1MDQzNFxcdTA0M0VcXHUwNDNBXFx1MDQ0M1xcdTA0M0NcXHUwNDM1XFx1MDQzRFxcdTA0NDIgPyAnXG4gICAgICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIE1vZGFsUGFnZURlbGV0ZTtcbn0oUmVhY3QuUHVyZUNvbXBvbmVudCk7XG4vKlxyXG5Nb2RhbFBhZ2VEZWxldGUucHJvcFR5cGVzID0ge1xyXG4gICAgbW9kYWxQYWdlQnRuQ2xpY2s6IFByb3BUeXBlcy5mdW5jLmlzUmVxdWlyZWRcclxufVxyXG4qL1xuXG5cbm1vZHVsZS5leHBvcnRzID0gTW9kYWxQYWdlRGVsZXRlO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvY29tcG9uZW50cy9tb2RhbHBhZ2UvbW9kYWxwYWdlLWRlbGV0ZS9tb2RhbFBhZ2UtZGVsZXRlLmpzeFxuLy8gbW9kdWxlIGlkID0gMTc3XG4vLyBtb2R1bGUgY2h1bmtzID0gNSIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgaWNvbjogJ2ltYWdlcy9pY29ucy9kZWxldGUucG5nJ1xufTtcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2NvbXBvbmVudHMvbW9kYWxwYWdlL21vZGFscGFnZS1kZWxldGUvbW9kYWxwYWdlLWRlbGV0ZS1zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDE3OFxuLy8gbW9kdWxlIGNodW5rcyA9IDUiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFByb3BUeXBlcyA9IHJlcXVpcmUoJ3Byb3AtdHlwZXMnKTtcblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKSxcbiAgICBNb2RhbFBhZ2UgPSByZXF1aXJlKCcuLi9tb2RhbFBhZ2UuanN4JyksXG4gICAgc3R5bGVzID0gcmVxdWlyZSgnLi4vbW9kYWxwYWdlLWluZm8vbW9kYWxwYWdlLWluZm8tc3R5bGVzJyk7XG5cbnZhciBNb2RhbFBhZ2VJbmZvID0gZnVuY3Rpb24gKF9SZWFjdCRQdXJlQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKE1vZGFsUGFnZUluZm8sIF9SZWFjdCRQdXJlQ29tcG9uZW50KTtcblxuICAgIGZ1bmN0aW9uIE1vZGFsUGFnZUluZm8ocHJvcHMpIHtcbiAgICAgICAgX2NsYXNzQ2FsbENoZWNrKHRoaXMsIE1vZGFsUGFnZUluZm8pO1xuXG4gICAgICAgIHZhciBfdGhpcyA9IF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHRoaXMsIChNb2RhbFBhZ2VJbmZvLl9fcHJvdG9fXyB8fCBPYmplY3QuZ2V0UHJvdG90eXBlT2YoTW9kYWxQYWdlSW5mbykpLmNhbGwodGhpcywgcHJvcHMpKTtcblxuICAgICAgICBfdGhpcy5zdGF0ZSA9IHtcbiAgICAgICAgICAgIHNob3c6IF90aGlzLnByb3BzLnNob3dcbiAgICAgICAgfTtcblxuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuXG4gICAgX2NyZWF0ZUNsYXNzKE1vZGFsUGFnZUluZm8sIFt7XG4gICAgICAgIGtleTogJ2NvbXBvbmVudFdpbGxSZWNlaXZlUHJvcHMnLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gY29tcG9uZW50V2lsbFJlY2VpdmVQcm9wcyhuZXh0UHJvcHMpIHtcbiAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoeyBzaG93OiBuZXh0UHJvcHMuc2hvdyB9KTtcbiAgICAgICAgfVxuICAgIH0sIHtcbiAgICAgICAga2V5OiAncmVuZGVyJyxcbiAgICAgICAgdmFsdWU6IGZ1bmN0aW9uIHJlbmRlcigpIHtcblxuICAgICAgICAgICAgdmFyIHN5c3RlbU1lc3NhZ2UgPSB0aGlzLnByb3BzLnN5c3RlbU1lc3NhZ2UgPyB0aGlzLnByb3BzLnN5c3RlbU1lc3NhZ2UgOiAnJyxcbiAgICAgICAgICAgICAgICBtb2RhbE9iamVjdHMgPSBbJ2J0bk9rJ107XG5cbiAgICAgICAgICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAgICAgICAgIE1vZGFsUGFnZSxcbiAgICAgICAgICAgICAgICB7IHJlZjogJ21vZGFsUGFnZScsXG4gICAgICAgICAgICAgICAgICAgIG1vZGFsUGFnZUJ0bkNsaWNrOiB0aGlzLnByb3BzLm1vZGFsUGFnZUJ0bkNsaWNrLFxuICAgICAgICAgICAgICAgICAgICBtb2RhbFBhZ2VOYW1lOiAnV2FybmluZyEnLFxuICAgICAgICAgICAgICAgICAgICBtb2RhbE9iamVjdHM6IG1vZGFsT2JqZWN0cyB9LFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IHJlZjogJ2NvbnRhaW5lcicgfSxcbiAgICAgICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudCgnaW1nJywgeyByZWY6ICdpbWFnZScsIHNyYzogc3R5bGVzLmljb24gfSksXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICAgICAnc3BhbicsXG4gICAgICAgICAgICAgICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgICAgICAgICAgICAgJyAnLFxuICAgICAgICAgICAgICAgICAgICAgICAgc3lzdGVtTWVzc2FnZSxcbiAgICAgICAgICAgICAgICAgICAgICAgICcgJ1xuICAgICAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICAgICAgKVxuICAgICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgIH1dKTtcblxuICAgIHJldHVybiBNb2RhbFBhZ2VJbmZvO1xufShSZWFjdC5QdXJlQ29tcG9uZW50KTtcblxuTW9kYWxQYWdlSW5mby5wcm9wVHlwZXMgPSB7XG4gICAgc3lzdGVtTWVzc2FnZTogUHJvcFR5cGVzLnN0cmluZyxcbiAgICBtb2RhbFBhZ2VCdG5DbGljazogUHJvcFR5cGVzLmZ1bmNcbn07XG5cbm1vZHVsZS5leHBvcnRzID0gTW9kYWxQYWdlSW5mbztcblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL2Zyb250ZW5kL2NvbXBvbmVudHMvbW9kYWxwYWdlL21vZGFscGFnZS1pbmZvL21vZGFsUGFnZS1pbmZvLmpzeFxuLy8gbW9kdWxlIGlkID0gMTc5XG4vLyBtb2R1bGUgY2h1bmtzID0gNSIsIid1c2Ugc3RyaWN0JztcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gICAgaWNvbjogJ2ltYWdlcy9pY29ucy9pbmZvLnBuZydcbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9jb21wb25lbnRzL21vZGFscGFnZS9tb2RhbHBhZ2UtaW5mby9tb2RhbHBhZ2UtaW5mby1zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDE4MFxuLy8gbW9kdWxlIGNodW5rcyA9IDUiLCIndXNlIHN0cmljdCc7XG5cbnZhciBfY3JlYXRlQ2xhc3MgPSBmdW5jdGlvbiAoKSB7IGZ1bmN0aW9uIGRlZmluZVByb3BlcnRpZXModGFyZ2V0LCBwcm9wcykgeyBmb3IgKHZhciBpID0gMDsgaSA8IHByb3BzLmxlbmd0aDsgaSsrKSB7IHZhciBkZXNjcmlwdG9yID0gcHJvcHNbaV07IGRlc2NyaXB0b3IuZW51bWVyYWJsZSA9IGRlc2NyaXB0b3IuZW51bWVyYWJsZSB8fCBmYWxzZTsgZGVzY3JpcHRvci5jb25maWd1cmFibGUgPSB0cnVlOyBpZiAoXCJ2YWx1ZVwiIGluIGRlc2NyaXB0b3IpIGRlc2NyaXB0b3Iud3JpdGFibGUgPSB0cnVlOyBPYmplY3QuZGVmaW5lUHJvcGVydHkodGFyZ2V0LCBkZXNjcmlwdG9yLmtleSwgZGVzY3JpcHRvcik7IH0gfSByZXR1cm4gZnVuY3Rpb24gKENvbnN0cnVjdG9yLCBwcm90b1Byb3BzLCBzdGF0aWNQcm9wcykgeyBpZiAocHJvdG9Qcm9wcykgZGVmaW5lUHJvcGVydGllcyhDb25zdHJ1Y3Rvci5wcm90b3R5cGUsIHByb3RvUHJvcHMpOyBpZiAoc3RhdGljUHJvcHMpIGRlZmluZVByb3BlcnRpZXMoQ29uc3RydWN0b3IsIHN0YXRpY1Byb3BzKTsgcmV0dXJuIENvbnN0cnVjdG9yOyB9OyB9KCk7XG5cbmZ1bmN0aW9uIF9jbGFzc0NhbGxDaGVjayhpbnN0YW5jZSwgQ29uc3RydWN0b3IpIHsgaWYgKCEoaW5zdGFuY2UgaW5zdGFuY2VvZiBDb25zdHJ1Y3RvcikpIHsgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkNhbm5vdCBjYWxsIGEgY2xhc3MgYXMgYSBmdW5jdGlvblwiKTsgfSB9XG5cbmZ1bmN0aW9uIF9wb3NzaWJsZUNvbnN0cnVjdG9yUmV0dXJuKHNlbGYsIGNhbGwpIHsgaWYgKCFzZWxmKSB7IHRocm93IG5ldyBSZWZlcmVuY2VFcnJvcihcInRoaXMgaGFzbid0IGJlZW4gaW5pdGlhbGlzZWQgLSBzdXBlcigpIGhhc24ndCBiZWVuIGNhbGxlZFwiKTsgfSByZXR1cm4gY2FsbCAmJiAodHlwZW9mIGNhbGwgPT09IFwib2JqZWN0XCIgfHwgdHlwZW9mIGNhbGwgPT09IFwiZnVuY3Rpb25cIikgPyBjYWxsIDogc2VsZjsgfVxuXG5mdW5jdGlvbiBfaW5oZXJpdHMoc3ViQ2xhc3MsIHN1cGVyQ2xhc3MpIHsgaWYgKHR5cGVvZiBzdXBlckNsYXNzICE9PSBcImZ1bmN0aW9uXCIgJiYgc3VwZXJDbGFzcyAhPT0gbnVsbCkgeyB0aHJvdyBuZXcgVHlwZUVycm9yKFwiU3VwZXIgZXhwcmVzc2lvbiBtdXN0IGVpdGhlciBiZSBudWxsIG9yIGEgZnVuY3Rpb24sIG5vdCBcIiArIHR5cGVvZiBzdXBlckNsYXNzKTsgfSBzdWJDbGFzcy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKHN1cGVyQ2xhc3MgJiYgc3VwZXJDbGFzcy5wcm90b3R5cGUsIHsgY29uc3RydWN0b3I6IHsgdmFsdWU6IHN1YkNsYXNzLCBlbnVtZXJhYmxlOiBmYWxzZSwgd3JpdGFibGU6IHRydWUsIGNvbmZpZ3VyYWJsZTogdHJ1ZSB9IH0pOyBpZiAoc3VwZXJDbGFzcykgT2JqZWN0LnNldFByb3RvdHlwZU9mID8gT2JqZWN0LnNldFByb3RvdHlwZU9mKHN1YkNsYXNzLCBzdXBlckNsYXNzKSA6IHN1YkNsYXNzLl9fcHJvdG9fXyA9IHN1cGVyQ2xhc3M7IH1cblxudmFyIFByb3BUeXBlcyA9IHJlcXVpcmUoJ3Byb3AtdHlwZXMnKTtcblxudmFyIHNpZGVCYXJTdHlsZXMgPSByZXF1aXJlKCcuL3NpZGViYXItc3R5bGVzJyksXG4gICAgUmVhY3QgPSByZXF1aXJlKCdyZWFjdCcpO1xuXG52YXIgU2lkZUJhckNvbnRhaW5lciA9IGZ1bmN0aW9uIChfUmVhY3QkQ29tcG9uZW50KSB7XG4gICAgX2luaGVyaXRzKFNpZGVCYXJDb250YWluZXIsIF9SZWFjdCRDb21wb25lbnQpO1xuXG4gICAgZnVuY3Rpb24gU2lkZUJhckNvbnRhaW5lcihwcm9wcykge1xuICAgICAgICBfY2xhc3NDYWxsQ2hlY2sodGhpcywgU2lkZUJhckNvbnRhaW5lcik7XG5cbiAgICAgICAgdmFyIF90aGlzID0gX3Bvc3NpYmxlQ29uc3RydWN0b3JSZXR1cm4odGhpcywgKFNpZGVCYXJDb250YWluZXIuX19wcm90b19fIHx8IE9iamVjdC5nZXRQcm90b3R5cGVPZihTaWRlQmFyQ29udGFpbmVyKSkuY2FsbCh0aGlzLCBwcm9wcykpO1xuXG4gICAgICAgIF90aGlzLnN0YXRlID0ge1xuICAgICAgICAgICAgd2lkdGg6IHByb3BzLndpZHRoLFxuICAgICAgICAgICAgY29udGVudFdpZHRoOiAnMTAwJScsXG4gICAgICAgICAgICBzaG93OiB0cnVlLFxuICAgICAgICAgICAgdG9vbEJhcjogcHJvcHMudG9vbGJhclxuICAgICAgICB9O1xuXG4gICAgICAgIF90aGlzLmJ0bkNsaWNrSGFuZGxlciA9IF90aGlzLmJ0bkNsaWNrSGFuZGxlci5iaW5kKF90aGlzKTtcbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cblxuICAgIF9jcmVhdGVDbGFzcyhTaWRlQmFyQ29udGFpbmVyLCBbe1xuICAgICAgICBrZXk6ICdidG5DbGlja0hhbmRsZXInLFxuICAgICAgICB2YWx1ZTogZnVuY3Rpb24gYnRuQ2xpY2tIYW5kbGVyKCkge1xuICAgICAgICAgICAgdmFyIHdpZHRoID0gdGhpcy5zdGF0ZS5zaG93ID8gJzIwcHgnIDogdGhpcy5wcm9wcy53aWR0aCxcbiAgICAgICAgICAgICAgICBjb250ZW50V2lkdGggPSB0aGlzLnN0YXRlLnNob3cgPyAnMXB4JyA6ICcxMDAlJyxcbiAgICAgICAgICAgICAgICBzaG93Q29udGVudCA9ICF0aGlzLnN0YXRlLnNob3c7XG5cbiAgICAgICAgICAgIHRoaXMuc2V0U3RhdGUoe1xuICAgICAgICAgICAgICAgIHdpZHRoOiB3aWR0aCxcbiAgICAgICAgICAgICAgICBjb250ZW50V2lkdGg6IGNvbnRlbnRXaWR0aCxcbiAgICAgICAgICAgICAgICBzaG93OiBzaG93Q29udGVudFxuICAgICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICB9LCB7XG4gICAgICAgIGtleTogJ3JlbmRlcicsXG4gICAgICAgIHZhbHVlOiBmdW5jdGlvbiByZW5kZXIoKSB7XG4gICAgICAgICAgICB2YXIgdG9vbEJhclN5bWJvbCA9IHRoaXMuc3RhdGUuc2hvdyA/ICc8JyA6ICc+JzsgLy9AdG9kbyBtb3ZlIHRvIHN0eWxlcyBmaWxlXG5cbiAgICAgICAgICAgIC8vcHJlcGFpcmUgc3R5bGVzXG4gICAgICAgICAgICB2YXIgc2lkZUJhckNvbnRhaW5lclN0eWxlID0gT2JqZWN0LmFzc2lnbih7fSwgc2lkZUJhclN0eWxlcy5zaWRlQmFyQ29udGFpbmVyU3R5bGUsIHsgd2lkdGg6IHRoaXMuc3RhdGUud2lkdGggfSwgeyBoZWlnaHQ6IHRoaXMucHJvcHMuaGVpZ2h0IH0pLFxuICAgICAgICAgICAgICAgIHRvb2xCYXJTdHlsZSA9IE9iamVjdC5hc3NpZ24oe30sIHNpZGVCYXJTdHlsZXMudG9vbEJhclN0eWxlLCB7IHZpc2liaWxpdHk6IHRoaXMucHJvcHMudG9vbGJhciA/ICd2aXNpYmxlJyA6ICdoaWRkZW4nIH0pLFxuICAgICAgICAgICAgICAgIGNvbnRlbnRTdHlsZSA9IE9iamVjdC5hc3NpZ24oe30sIHNpZGVCYXJTdHlsZXMuY29udGVudFN0eWxlLCB7IHZpc2liaWxpdHk6IHRoaXMuc3RhdGUuc2hvdyA/ICd2aXNpYmxlJyA6ICdoaWRkZW4nIH0pLFxuICAgICAgICAgICAgICAgIGJ1dHRvblN0eWxlID0gT2JqZWN0LmFzc2lnbih7fSwgc2lkZUJhclN0eWxlcy5idXR0b25TdHlsZSwge1xuICAgICAgICAgICAgICAgIGhlaWdodDogdGhpcy5wcm9wcy50b29sYmFyID8gc2lkZUJhclN0eWxlcy5idXR0b25TdHlsZS5oZWlnaHQgOiAnMCcsXG4gICAgICAgICAgICAgICAgdmlzaWJpbGl0eTogdGhpcy5wcm9wcy50b29sYmFyID8gJ3Zpc2libGUnIDogJ2hpZGRlbidcbiAgICAgICAgICAgIH0pO1xuXG4gICAgICAgICAgICByZXR1cm4gUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAnZGl2JyxcbiAgICAgICAgICAgICAgICB7IGlkOiAndG9vbEJhckNvbnRhaW5lcicsIHN0eWxlOiBzaWRlQmFyQ29udGFpbmVyU3R5bGUsIHJlZjogJ3Rvb2xiYXInIH0sXG4gICAgICAgICAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChcbiAgICAgICAgICAgICAgICAgICAgJ2RpdicsXG4gICAgICAgICAgICAgICAgICAgIHsgaWQ6ICdidG5CYXInLCBzdHlsZTogdG9vbEJhclN0eWxlIH0sXG4gICAgICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoJ2lucHV0JywgeyB0eXBlOiAnYnV0dG9uJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlZjogJ3NpZGViYXItYnV0dG9uJyxcbiAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBidXR0b25TdHlsZSxcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhbHVlOiB0b29sQmFyU3ltYm9sLFxuICAgICAgICAgICAgICAgICAgICAgICAgb25DbGljazogdGhpcy5idG5DbGlja0hhbmRsZXJcbiAgICAgICAgICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICAgIFJlYWN0LmNyZWF0ZUVsZW1lbnQoXG4gICAgICAgICAgICAgICAgICAgICdkaXYnLFxuICAgICAgICAgICAgICAgICAgICB7IGlkOiAnY29udGVudCcsIHN0eWxlOiBjb250ZW50U3R5bGUsIHJlZjogJ2NvbnRlbnQnIH0sXG4gICAgICAgICAgICAgICAgICAgIHRoaXMucHJvcHMuY2hpbGRyZW5cbiAgICAgICAgICAgICAgICApXG4gICAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgfV0pO1xuXG4gICAgcmV0dXJuIFNpZGVCYXJDb250YWluZXI7XG59KFJlYWN0LkNvbXBvbmVudCk7XG5cblNpZGVCYXJDb250YWluZXIucHJvcFR5cGVzID0ge1xuICAgIHRvb2xiYXI6IFByb3BUeXBlcy5ib29sLFxuICAgIHdpZHRoOiBQcm9wVHlwZXMuc3RyaW5nLFxuICAgIGhlaWd0aDogUHJvcFR5cGVzLnN0cmluZ1xufTtcblxuU2lkZUJhckNvbnRhaW5lci5kZWZhdWx0UHJvcHMgPSB7XG4gICAgdG9vbGJhcjogdHJ1ZSxcbiAgICB3aWR0aDogJzEwMCUnLFxuICAgIGhlaWdodDogJzEwMCUnXG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IFNpZGVCYXJDb250YWluZXI7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9jb21wb25lbnRzL3NpZGViYXIvc2lkZWJhci5qc3hcbi8vIG1vZHVsZSBpZCA9IDE4MVxuLy8gbW9kdWxlIGNodW5rcyA9IDUiLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIHNpZGVCYXJDb250YWluZXJTdHlsZToge1xuICAgICAgICB3aWR0aDogJzEwMCUnLFxuICAgICAgICBoZWlnaHQ6ICc1MDBweCcsXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6JzFweCBzb2xpZCBncmV5JyxcclxuICAgICAgICAqL1xuICAgICAgICBiYWNrZ3JvdW5kOiAnd2hpdGUnXG4gICAgfSxcblxuICAgIHRvb2xCYXJTdHlsZToge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGhlaWdodDogJ2F1dG8nLFxuICAgICAgICB3aWR0aDogJzEwMCUnLFxuICAgICAgICBib3JkZXI6ICcxcHggc29saWQgYmxhY2snLFxuICAgICAgICBiYWNrZ3JvdW5kOiAnZ3JheScsXG4gICAgICAgIHZpc2liaWxpdHk6ICd2aXNpYmxlJ1xuICAgIH0sXG4gICAgY29udGVudFN0eWxlOiB7XG4gICAgICAgIGhlaWdodDogJ2luaGVyaXQnLFxuICAgICAgICB3aWR0aDogJzEwMCUnXG4gICAgfSxcblxuICAgIGJ1dHRvblN0eWxlOiB7XG4gICAgICAgIHBvc2l0aW9uOiAncmVsYXRpdmUnLFxuICAgICAgICBoZWlnaHQ6ICcyMHB4JyxcbiAgICAgICAgd2lkdGg6ICcyMHB4J1xuICAgIH1cbn07XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9jb21wb25lbnRzL3NpZGViYXIvc2lkZWJhci1zdHlsZXMuanNcbi8vIG1vZHVsZSBpZCA9IDE4MlxuLy8gbW9kdWxlIGNodW5rcyA9IDUiLCIndXNlIHN0cmljdCc7XG4vKipcclxuICog0JLQtdGA0L3QtdGCINC60L7QvNC/0L7QvdC10YIg0LTQu9GPIHRvb2xiYXJNZW51XHJcbiAqIEBidG5QYXJhbXMg0J/QsNGA0LDQvNC10YLRgNGLINC60L3QvtC/0L7QulxyXG4gKiBAdXNlckRhdGEg0JTQsNC90L3Ri9C1INC/0L7Qu9GM0LfQvtCy0LDRgtC10LvRj1xyXG4gKiBAcmV0dXJucyB7WE1MfVxyXG4gKi9cblxudmFyIFJlYWN0ID0gcmVxdWlyZSgncmVhY3QnKTtcbnZhciBNZW51VG9vbEJhciA9IHJlcXVpcmUoJy4vLi4vY29tcG9uZW50cy9tZW51LXRvb2xiYXIvbWVudS10b29sYmFyLmpzeCcpO1xudmFyIHJlbmRlcm1lbnVUb29sQmFyID0gZnVuY3Rpb24gcmVuZGVybWVudVRvb2xCYXIoYnRuUGFyYW1zLCB1c2VyRGF0YSkge1xuICAgIHJldHVybiBSZWFjdC5jcmVhdGVFbGVtZW50KFxuICAgICAgICAnZGl2JyxcbiAgICAgICAgbnVsbCxcbiAgICAgICAgUmVhY3QuY3JlYXRlRWxlbWVudChNZW51VG9vbEJhciwgeyBlZGl0ZWQ6IGZhbHNlLCBwYXJhbXM6IGJ0blBhcmFtcywgdXNlckRhdGE6IHVzZXJEYXRhLCBidG5TdGFydENsaWNrOiB1bmRlZmluZWQuYnRuU3RhcnRDbGlja0hhbmxlciB9KVxuICAgICk7XG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IHJlbmRlcm1lbnVUb29sQmFyO1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvbWl4aW4vbWVudVRvb2xCYXIuanN4XG4vLyBtb2R1bGUgaWQgPSAxODNcbi8vIG1vZHVsZSBjaHVua3MgPSA1IDciLCIndXNlIHN0cmljdCc7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICAgIGNvbnRhaW5lcjoge1xuICAgICAgICBkaXNwbGF5OiAnZmxleCcsXG4gICAgICAgIGZsZXhGbG93OiAncm93IHdyYXAnLFxuICAgICAgICBoZWlnaHQ6ICc4NyUnXG4gICAgICAgIC8qXHJcbiAgICAgICAgICAgICAgICBib3JkZXI6ICczcHggc29saWQgYnJvd24nXHJcbiAgICAgICAgKi9cbiAgICB9LFxuICAgIHdyYXBwZXI6IHtcbiAgICAgICAgZGlzcGxheTogJ2ZsZXgnLFxuICAgICAgICBoZWlnaHQ6ICcxMDAlJyxcbiAgICAgICAgZmxleDogJzEgMTAwJScsXG4gICAgICAgIGFsaWduSXRlbXM6ICdzdHJldGNoJyxcbiAgICAgICAgZmxleERpcmVjdGlvbjogJ3JvdydcbiAgICB9XG59O1xuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vZnJvbnRlbmQvZG9jcy9kb2MtcmVnaXN0ZXIvZG9jLXJlZ2lzdGVyLXN0eWxlcy5qc1xuLy8gbW9kdWxlIGlkID0gMTg0XG4vLyBtb2R1bGUgY2h1bmtzID0gNSIsIid1c2Ugc3RyaWN0JztcblxudmFyIGZsdXggPSByZXF1aXJlKCdmbHV4aWZ5JyksXG4gICAgT1JERVJfQlkgPSBbeyBjb2x1bW46ICdpZCcsIGRpcmVjdGlvbjogJ2Rlc2MnIH1dO1xuXG52YXIgZG9jc1N0b3JlID0gZmx1eC5jcmVhdGVTdG9yZSh7XG4gICAgaWQ6ICdkb2NzU3RvcmUnLFxuICAgIGluaXRpYWxTdGF0ZToge1xuICAgICAgICBkb2NzR3JpZDogMCxcbiAgICAgICAgZG9jc0xpc3Q6ICcnLFxuICAgICAgICBuYW1lOiAndmxhZCcsXG4gICAgICAgIGRhdGE6IFtdLFxuICAgICAgICBzb3J0Qnk6IE9SREVSX0JZLFxuICAgICAgICBzcWxXaGVyZTogJycsXG4gICAgICAgIHN5c3RlbU1lc3NhZ2U6IG51bGwsXG4gICAgICAgIHVzZXJEYXRhOiB7fSxcbiAgICAgICAgbG9nZWRJbjogZmFsc2VcbiAgICB9LFxuICAgIGFjdGlvbkNhbGxiYWNrczoge1xuICAgICAgICBzeXN0ZW1NZXNzYWdlQ2hhbmdlOiBmdW5jdGlvbiBzeXN0ZW1NZXNzYWdlQ2hhbmdlKHVwZGF0ZXIsIHZhbHVlKSB7XG4gICAgICAgICAgICB1cGRhdGVyLnNldCh7IHN5c3RlbU1lc3NhZ2U6IHZhbHVlIH0pO1xuICAgICAgICB9LFxuICAgICAgICBzcWxXaGVyZUNoYW5nZTogZnVuY3Rpb24gc3FsV2hlcmVDaGFuZ2UodXBkYXRlciwgdmFsdWUpIHtcbiAgICAgICAgICAgIHVwZGF0ZXIuc2V0KHsgc3FsV2hlcmU6IHZhbHVlIH0pO1xuICAgICAgICAgICAgcmVxdWVyeSh7IG5hbWU6ICdkb2NzR3JpZCcsIHZhbHVlOiB0aGlzLmRvY3NMaXN0IH0pO1xuICAgICAgICB9LFxuICAgICAgICBzb3J0QnlDaGFuZ2U6IGZ1bmN0aW9uIHNvcnRCeUNoYW5nZSh1cGRhdGVyLCB2YWx1ZSkge1xuICAgICAgICAgICAgdXBkYXRlci5zZXQoeyBzb3J0Qnk6IHZhbHVlIH0pO1xuICAgICAgICAgICAgcmVxdWVyeSh7IG5hbWU6ICdkb2NzR3JpZCcsIHZhbHVlOiB0aGlzLmRvY3NMaXN0LCBzb3J0Qnk6IHZhbHVlIH0pO1xuICAgICAgICB9LFxuICAgICAgICBBZGQ6IGZ1bmN0aW9uIEFkZCgpIHtcbiAgICAgICAgICAgIGFkZCh0aGlzLmRvY3NMaXN0KTtcbiAgICAgICAgfSxcbiAgICAgICAgRWRpdDogZnVuY3Rpb24gRWRpdCgpIHtcbiAgICAgICAgICAgIGlmICh0aGlzLmRvY3NMaXN0ICYmIHRoaXMuZG9jc0dyaWQpIHtcbiAgICAgICAgICAgICAgICBlZGl0KHRoaXMuZG9jc0xpc3QsIHRoaXMuZG9jc0dyaWQpO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBjb25zb2xlLmVycm9yKCfQotC40L8g0LTQvtC60YPQvNC10L3RgtCwINC40LvQuCDQtNC+0LrRg9C80LXQvdGCINC90LUg0LLRi9Cx0YDQsNC9JywgdGhpcy5kb2NzTGlzdCwgdGhpcy5kb2NzR3JpZCk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH0sXG4gICAgICAgIERlbGV0ZTogZnVuY3Rpb24gRGVsZXRlKCkge1xuICAgICAgICAgICAgdmFyIGRvY1R5cGVJZCA9IHRoaXMuZG9jc0xpc3Q7XG4gICAgICAgICAgICByZXF1ZXJ5Rm9yQWN0aW9uKCdkZWxldGUnLCBmdW5jdGlvbiAoZXJyLCBkYXRhKSB7XG4gICAgICAgICAgICAgICAgaWYgKGVycikge1xuICAgICAgICAgICAgICAgICAgICBmbHV4LmRvQWN0aW9uKCdzeXN0ZW1NZXNzYWdlQ2hhbmdlJywgZXJyKTsgLy8g0L/QuNGI0LXQvCDQuNC30LzQtdC90LXQvdC40Y8g0LIg0YXRgNCw0L3QuNC70LjRidC1XG4gICAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignc3lzdGVtTWVzc2FnZUNoYW5nZScsIG51bGwpOyAvLyDQv9C40YjQtdC8INC40LfQvNC10L3QtdC90LjRjyDQsiDRhdGA0LDQvdC40LvQuNGJ0LVcbiAgICAgICAgICAgICAgICAgICAgcmVxdWVyeSh7IG5hbWU6ICdkb2NzR3JpZCcsIHZhbHVlOiBkb2NUeXBlSWQgfSk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSk7XG4gICAgICAgIH0sXG4gICAgICAgIFByaW50OiBmdW5jdGlvbiBQcmludCgpIHtcbiAgICAgICAgICAgIGNvbnNvbGUubG9nKCdidXR0b24gUHJpbnQgY2xpa2VkIScpO1xuICAgICAgICB9LFxuICAgICAgICBjaGFuZ2VOYW1lOiBmdW5jdGlvbiBjaGFuZ2VOYW1lKHVwZGF0ZXIsIG5hbWUpIHtcbiAgICAgICAgICAgIC8vIFN0b3JlcyB1cGRhdGVzIGFyZSBvbmx5IG1hZGUgaW5zaWRlIHN0b3JlJ3MgYWN0aW9uIGNhbGxiYWNrc1xuICAgICAgICAgICAgdXBkYXRlci5zZXQoeyBuYW1lOiBuYW1lIH0pO1xuICAgICAgICB9LFxuICAgICAgICBkb2NzR3JpZENoYW5nZTogZnVuY3Rpb24gZG9jc0dyaWRDaGFuZ2UodXBkYXRlciwgdmFsdWUpIHtcbiAgICAgICAgICAgIC8vIFN0b3JlcyB1cGRhdGVzIGFyZSBvbmx5IG1hZGUgaW5zaWRlIHN0b3JlJ3MgYWN0aW9uIGNhbGxiYWNrc1xuICAgICAgICAgICAgdXBkYXRlci5zZXQoeyBkb2NzR3JpZDogdmFsdWUgfSk7XG4gICAgICAgIH0sXG4gICAgICAgIGRvY3NMaXN0Q2hhbmdlOiBmdW5jdGlvbiBkb2NzTGlzdENoYW5nZSh1cGRhdGVyLCB2YWx1ZSkge1xuICAgICAgICAgICAgLy8gU3RvcmVzIHVwZGF0ZXMgYXJlIG9ubHkgbWFkZSBpbnNpZGUgc3RvcmUncyBhY3Rpb24gY2FsbGJhY2tzXG4gICAgICAgICAgICB2YXIgbGFzdFZhbHVlID0gZmx1eC5zdG9yZXMuZG9jc1N0b3JlLmRvY3NMaXN0IHx8ICdET0snO1xuICAgICAgICAgICAgaWYgKHZhbHVlICE9PSBsYXN0VmFsdWUpIHtcbiAgICAgICAgICAgICAgICB1cGRhdGVyLnNldCh7IGRvY3NMaXN0OiB2YWx1ZSB9KTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGZsdXguZG9BY3Rpb24oJ3NxbFdoZXJlQ2hhbmdlJywgJycpO1xuICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignc29ydEJ5Q2hhbmdlJywgT1JERVJfQlkpO1xuICAgICAgICAgICAgcmVxdWVyeSh7IG5hbWU6ICdkb2NzR3JpZCcsIHZhbHVlOiB2YWx1ZSB9KTtcblxuICAgICAgICAgICAgLy8gICAgICAgICAgICBsb2NhbFN0b3JhZ2VbJ2RvY3NMaXN0J10gPSB2YWx1ZTtcbiAgICAgICAgfSxcbiAgICAgICAgZGF0YUNoYW5nZTogZnVuY3Rpb24gZGF0YUNoYW5nZSh1cGRhdGVyLCB2YWx1ZSkge1xuICAgICAgICAgICAgLy8gU3RvcmVzIHVwZGF0ZXMgYXJlIG9ubHkgbWFkZSBpbnNpZGUgc3RvcmUncyBhY3Rpb24gY2FsbGJhY2tzXG4gICAgICAgICAgICB1cGRhdGVyLnNldCh7IGRhdGE6IHZhbHVlIH0pO1xuXG4gICAgICAgICAgICBpZiAoIXRoaXMuZG9jc0dyaWQpIHtcbiAgICAgICAgICAgICAgICB2YXIgZ3JpZFZhbHVlID0gdmFsdWVbMV0uZGF0YVswXS5kYXRhWzBdLmlkO1xuICAgICAgICAgICAgICAgIGZsdXguZG9BY3Rpb24oJ2RvY3NHcmlkQ2hhbmdlJywgZ3JpZFZhbHVlKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgaWYgKCF0aGlzLmRvY3NMaXN0KSB7XG4gICAgICAgICAgICAgICAgdmFyIHRyZWVWYWx1ZSA9IHZhbHVlWzBdLnZhbHVlO1xuICAgICAgICAgICAgICAgIGZsdXguZG9BY3Rpb24oJ2RvY3NMaXN0Q2hhbmdlJywgdHJlZVZhbHVlKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfSxcbiAgICAgICAgdXNlckRhdGFDaGFuZ2U6IGZ1bmN0aW9uIHVzZXJEYXRhQ2hhbmdlKHVwZGF0ZXIsIHZhbHVlKSB7XG4gICAgICAgICAgICB1cGRhdGVyLnNldCh7IHVzZXJEYXRhOiB2YWx1ZSB9KTtcblxuICAgICAgICAgICAgdmFyIGxvZ2VkSW4gPSAhIXVzZXJEYXRhO1xuICAgICAgICAgICAgdXBkYXRlci5zZXQoeyBsb2dlZEluOiBsb2dlZEluIH0pO1xuICAgICAgICB9XG5cbiAgICB9XG59KTtcblxudmFyIGVkaXQgPSBmdW5jdGlvbiBlZGl0KGRvY1R5cGVJZCwgZG9jSWQpIHtcbiAgICBkb2N1bWVudC5sb2NhdGlvbi5ocmVmID0gXCIvZG9jdW1lbnQvXCIgKyBkb2NUeXBlSWQgKyBkb2NJZDtcbn07XG5cbnZhciBhZGQgPSBmdW5jdGlvbiBhZGQoZG9jVHlwZUlkKSB7XG4gICAgZG9jdW1lbnQubG9jYXRpb24uaHJlZiA9IFwiL2RvY3VtZW50L1wiICsgZG9jVHlwZUlkICsgJzAnO1xufTtcblxudmFyIHJlcXVlcnlGb3JBY3Rpb24gPSBmdW5jdGlvbiByZXF1ZXJ5Rm9yQWN0aW9uKGFjdGlvbiwgY2FsbGJhY2spIHtcbiAgICB2YXIgQUNUSU9OX0xJU1QgPSB7ICdkZWxldGUnOiAnREVMRVRFJyB9LFxuICAgICAgICBBUEkgPSAnL2FwaS9kb2MnO1xuICAgIGlmICghd2luZG93LmpRdWVyeSB8fCAhJCkgcmV0dXJuOyAvLyDQtNC70Y8g0YLQtdGB0YLQvtCyXG5cbiAgICAvLyDQvNC10YLQvtC0INC+0LHQtdGB0L/QtdGH0LjRgiDQt9Cw0L/RgNC+0YEg0L3QsCDQstGL0L/QvtC70L3QtdC90LjQtVxuICAgIHZhciBkb2NJZCA9IGRvY3NTdG9yZS5kb2NzR3JpZCxcbiAgICAgICAgZG9jVHlwZUlkID0gZG9jc1N0b3JlLmRvY3NMaXN0O1xuXG4gICAgaWYgKCFkb2NJZCB8fCB0eXBlb2YgZG9jSWQgPT0gJ3N0cmluZycpIHtcbiAgICAgICAgZG9jSWQgPSAwO1xuICAgIH1cblxuICAgIGlmICghZG9jSWQpIHtcbiAgICAgICAgLy8gZG9jIG5vdCBzZWxlY3RlZFxuICAgICAgICB2YXIgZGF0YSA9IGRvY3NTdG9yZS5kYXRhO1xuICAgICAgICBkYXRhLmZvckVhY2goZnVuY3Rpb24gKHJvdykge1xuICAgICAgICAgICAgLy9AdG9kbyDQn9GA0LjQstC10YHRgtC4INCyINCx0L7QttC10YHQutC40Lkg0LLQuNC0XG4gICAgICAgICAgICBpZiAoIWRvY1R5cGVJZCAmJiByb3cubmFtZSA9PSAnZG9jc0xpc3QnKSB7XG4gICAgICAgICAgICAgICAgLy8g0L3QtSDQvdCw0LfQvdCw0YfQtdC9INGC0LjQvyDQtNC+0LrRg9C80LXQvdGC0LBcbiAgICAgICAgICAgICAgICBkb2NUeXBlSWQgPSByb3dbJ3ZhbHVlJ107XG4gICAgICAgICAgICAgICAgZmx1eC5kb0FjdGlvbignZG9jc0xpc3RDaGFuZ2UnLCBkb2NUeXBlSWQpO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAocm93Lm5hbWUgPT0gJ2RvY3NHcmlkJykge1xuICAgICAgICAgICAgICAgIGRvY0lkID0gcm93LmRhdGFbMF0uZGF0YVswXS5pZDtcbiAgICAgICAgICAgICAgICBmbHV4LmRvQWN0aW9uKCdkb2NzR3JpZENoYW5nZScsIGRvY0lkKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfSk7XG4gICAgfVxuXG4gICAgdmFyIHBhcmFtZXRlcnMgPSB7XG4gICAgICAgIGRvY0lkOiBkb2NJZCxcbiAgICAgICAgZG9jX3R5cGVfaWQ6IGRvY1R5cGVJZFxuICAgIH07XG5cbiAgICAkLmFqYXgoe1xuICAgICAgICB1cmw6IEFQSSxcbiAgICAgICAgdHlwZTogQUNUSU9OX0xJU1RbQUNUSU9OXSB8fCAnUE9TVCcsXG4gICAgICAgIGRhdGFUeXBlOiAnanNvbicsXG4gICAgICAgIGRhdGE6IHtcbiAgICAgICAgICAgIGFjdGlvbjogYWN0aW9uLFxuICAgICAgICAgICAgZGF0YTogSlNPTi5zdHJpbmdpZnkocGFyYW1ldGVycylcbiAgICAgICAgfSxcbiAgICAgICAgY2FjaGU6IGZhbHNlLFxuICAgICAgICBzdWNjZXNzOiBmdW5jdGlvbiBzdWNjZXNzKGRhdGEpIHtcbiAgICAgICAgICAgIC8vINC00L7Qu9C20L3RiyDQv9C+0LvRg9GH0LjRgtGMINC+0LHRitC10LrRgiAtINGA0LXQt9GD0LvRjNGC0LDRglxuICAgICAgICAgICAgdmFyIGVycm9yTWVzc3NhZ2UgPSBudWxsO1xuICAgICAgICAgICAgaWYgKGRhdGEucmVzdWx0ID09ICdFcnJvcicpIHtcbiAgICAgICAgICAgICAgICBlcnJvck1lc3NzYWdlID0gJ0Vycm9yLCAnICsgZGF0YS5tZXNzYWdlO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBjYWxsYmFjayhlcnJvck1lc3NzYWdlLCBkYXRhKTtcbiAgICAgICAgfSxcbiAgICAgICAgZXJyb3I6IGZ1bmN0aW9uIGVycm9yKHhociwgc3RhdHVzLCBlcnIpIHtcbiAgICAgICAgICAgIGNvbnNvbGUuZXJyb3IoJy9lcnJvcicsIHN0YXR1cywgZXJyLnRvU3RyaW5nKCkpO1xuICAgICAgICAgICAgY2FsbGJhY2soZXJyLCBudWxsKTtcbiAgICAgICAgfVxuICAgIH0pO1xufTtcblxudmFyIHJlcXVlcnkgPSBmdW5jdGlvbiByZXF1ZXJ5KGNvbXBvbmVudCkge1xuICAgIGlmICghd2luZG93LmpRdWVyeSkgcmV0dXJuOyAvLyDQtNC70Y8g0YLQtdGB0YLQvtCyXG5cbiAgICAvLyDQvNC10YLQvtC0INC+0LHQtdGB0L/QtdGH0LjRgiDQv9C+0LvRg9GH0LXQvdC40LUg0LTQsNC90L3Ri9GFINC+0YIg0YHQtdGA0LLQtdGA0LBcbiAgICAvLyBjb21wb25lbnQgPSB0aGlzLnN0YXRlLmNvbXBvbmVudHNbbmFtZV1cbiAgICAvLyDQtdGB0LvQuCDQv9Cw0YDQsNC80LXRgtGA0Ysg0L3QtSDQt9Cw0LTQsNC90YssINCz0YDRg9C30LjQvCDQstGB0LVcblxuICAgIHZhciBjb21wb25lbnRzID0gZG9jc1N0b3JlLmRhdGE7XG5cbiAgICAvLyDRhNC40LvRjNGC0YDRg9C10Lwg0YHQv9C40YHQvtC6INC60L7QvNC/0L7QvdC10L3RgtC+0LJcbiAgICB2YXIgY29tcG9uZW50c0ZvclVwZGF0ZSA9IGNvbXBvbmVudHMuZmlsdGVyKGZ1bmN0aW9uIChpdGVtKSB7XG4gICAgICAgIC8vINC40YnQtdC8INC+0LHRitC10LrRgiDQv9C+INC90LDQuNC80LXQvdC+0LLQsNC90LjRji4g0LjQu9C4INCy0LXRgNC90LXQvCDQstGB0LUg0LXRgdC70Lgg0L/QsNGA0LDQvNC10YLRgCDQvdC1INC30LDQtNCw0L1cbiAgICAgICAgaWYgKGNvbXBvbmVudC5uYW1lID09ICcnIHx8IGl0ZW0ubmFtZSA9PSBjb21wb25lbnQubmFtZSkge1xuICAgICAgICAgICAgcmV0dXJuIGl0ZW0ubmFtZTtcbiAgICAgICAgfVxuICAgIH0pO1xuXG4gICAgLy8g0YHQvtGA0YLQuNGA0L7QstC60LBcbiAgICB2YXIgc3FsU29ydEJ5ID0gJycsXG4gICAgICAgIHNxbFdoZXJlID0gZG9jc1N0b3JlLnNxbFdoZXJlIHx8ICcnLFxuICAgICAgICBzb3J0QnlBcnJheSA9IGRvY3NTdG9yZS5zb3J0Qnk7XG5cbiAgICBpZiAoZG9jc1N0b3JlLnNvcnRCeSkge1xuICAgICAgICBmb3IgKHZhciBpID0gMDsgaSA8IHNvcnRCeUFycmF5Lmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgICBpZiAoaSA+IDApIHtcbiAgICAgICAgICAgICAgICBzcWxTb3J0QnkgPSBzcWxTb3J0QnkgKyAnLCc7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBzcWxTb3J0QnkgPSBzcWxTb3J0QnkgKyBzb3J0QnlBcnJheVtpXS5jb2x1bW4gKyAnICcgKyBzb3J0QnlBcnJheVtpXS5kaXJlY3Rpb247XG4gICAgICAgIH1cbiAgICB9XG5cbiAgICB2YXIgVVJMID0gJy9hcGkvZG9jcyc7XG4gICAgJC5hamF4KHtcbiAgICAgICAgdXJsOiBVUkwsXG4gICAgICAgIHR5cGU6IFwiUE9TVFwiLFxuICAgICAgICBkYXRhVHlwZTogJ2pzb24nLFxuXG4gICAgICAgIGRhdGE6IHtcbiAgICAgICAgICAgIGRhdGFUeXBlOiAnY29tcG9uZW50JyxcbiAgICAgICAgICAgIGRvY1R5cGVJZDogMSxcbiAgICAgICAgICAgIGNvbXBvbmVudHM6IEpTT04uc3RyaW5naWZ5KGNvbXBvbmVudHNGb3JVcGRhdGUpLCAvLyDQutC+0LzQv9C+0L3QtdC90YLRiyDQtNC70Y8g0L7QsdC90L7QstC70LXQvdC40Y9cbiAgICAgICAgICAgIHBhcmFtZXRlcjogY29tcG9uZW50LnZhbHVlLCAvLyDQv9Cw0YDQsNC80LXRgtGA0YtcbiAgICAgICAgICAgIHNvcnRCeTogc3FsU29ydEJ5LCAvLyDRgdC+0YDRgtC40YDQvtCy0LrQsFxuICAgICAgICAgICAgbGFzdERvY0lkOiBkb2NzU3RvcmUuZG9jc0dyaWQsXG4gICAgICAgICAgICBzcWxXaGVyZTogc3FsV2hlcmUgLy8g0LTQuNC90LDQvNC40YfQtdGB0LrQuNC5INGE0LjQu9GM0YLRgCDQs9GA0LjQtNCwXG4gICAgICAgIH0sXG4gICAgICAgIGNhY2hlOiBmYWxzZSxcbiAgICAgICAgc3VjY2VzczogZnVuY3Rpb24gKGRhdGEpIHtcbiAgICAgICAgICAgIC8vINC00L7Qu9C20L3RiyDQv9C+0LvRg9GH0LjRgtGMINC+0LHRitC10LrRglxuICAgICAgICAgICAgdmFyIGNvbXBvbmVudHMgPSBbXTtcbiAgICAgICAgICAgIGRhdGEuZm9yRWFjaChmdW5jdGlvbiAoaXRlbSkge1xuICAgICAgICAgICAgICAgIC8vIGZpbmQgaXRlbVxuICAgICAgICAgICAgICAgIC8vINC+0LHQvdC+0LLQuNC8INC00LDQvdC90YvQtSDQvNCw0YHRgdC40LLQsCDQutC+0LzQv9C+0L3QtdC90YLQvtCyXG4gICAgICAgICAgICAgICAgY29tcG9uZW50cyA9IGRvY3NTdG9yZS5kYXRhLm1hcChmdW5jdGlvbiAoY29tcG9uZW50KSB7XG4gICAgICAgICAgICAgICAgICAgIGlmIChjb21wb25lbnQubmFtZSA9PSBpdGVtLm5hbWUpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIC8vIGZvdW5kXG4gICAgICAgICAgICAgICAgICAgICAgICBjb21wb25lbnQuZGF0YSA9IGl0ZW0uZGF0YTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICByZXR1cm4gY29tcG9uZW50O1xuICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICBmbHV4LmRvQWN0aW9uKCdkYXRhQ2hhbmdlJywgY29tcG9uZW50cyk7XG4gICAgICAgIH0uYmluZCh1bmRlZmluZWQpLFxuICAgICAgICBlcnJvcjogZnVuY3Rpb24gKHhociwgc3RhdHVzLCBlcnIpIHtcbiAgICAgICAgICAgIGNvbnNvbGUuZXJyb3IoJy9lcnJvcicsIHN0YXR1cywgZXJyLnRvU3RyaW5nKCkpO1xuICAgICAgICB9LmJpbmQodW5kZWZpbmVkKVxuICAgIH0pO1xufTtcblxubW9kdWxlLmV4cG9ydHMgPSBkb2NzU3RvcmU7XG5cblxuLy8vLy8vLy8vLy8vLy8vLy8vXG4vLyBXRUJQQUNLIEZPT1RFUlxuLy8gLi9mcm9udGVuZC9zdG9yZXMvZG9jc19zdG9yZS5qc1xuLy8gbW9kdWxlIGlkID0gMTg1XG4vLyBtb2R1bGUgY2h1bmtzID0gNSJdLCJtYXBwaW5ncyI6Ijs7Ozs7O0FBQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNUQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNqbEJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDckVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNKQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7Ozs7O0FDekVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNKQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNsR0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUM5QkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNsQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7Ozs7QUNsQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOzs7OyIsInNvdXJjZVJvb3QiOiIifQ==