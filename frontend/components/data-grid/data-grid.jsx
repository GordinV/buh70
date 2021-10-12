'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    ToolbarContainer = require('./../toolbar-container/toolbar-container.jsx'),
    GridButtonAdd = require('./../button-register/button-register-add/button-register-add.jsx'),
    GridButtonEdit = require('./../button-register/button-register-edit/button-register-edit.jsx'),
    GridButtonDelete = require('./../button-register/button-register-delete/button-register-delete.jsx'),
    ModalPageDelete = require('./../../components/modalpage/modalpage-delete/modalPage-delete.jsx'),
    InputCheckBox = require('./../../components/input-checkbox/input-checkbox.jsx'),
    keydown = require('react-keydown');

//const    KEYS = [38, 40]; // мониторим только стрелки вверх и внизх
let styles = require('./data-grid-styles');


const isExists = (object, prop) => {
    let result = false;
    if (object && (prop in object)) {
        result = true;
    }
    return result;
};

//@keydown @todo
class DataGrid extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            activeRow: 0,
            activeColumn: '',
            isDelete: false,
            sort: {
                name: null,
                direction: null
            },
            value: this.props.value ? this.props.value : 0,
            gridData: props.gridData,
            subtotals: props.subtotals ? props.subtotals : [],
            isSelect: this.props.isSelect,
        };

        this.handleGridHeaderClick = this.handleGridHeaderClick.bind(this);
        this.handleCellDblClick = this.handleCellDblClick.bind(this);
        this.handleKeyDown = this.handleKeyDown.bind(this);
        this.prepareTableRow = this.prepareTableRow.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
        this.getGridRowIndexById = this.getGridRowIndexById.bind(this);
        this.prepareTableFooter = this.prepareTableFooter.bind(this);
        this.getSum = this.getSum.bind(this);
        this.grid = [];

    }


    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        return nextProps;
        if (JSON.stringify(nextProps.gridData) !== JSON.stringify(prevState.gridData) ||
            JSON.stringify(nextProps.gridColumns) !== JSON.stringify(prevState.gridColumns) ||
            nextProps.gridData.length !== prevState.gridData.length ||
            nextProps.isSelect !== prevState.isSelect) {
            return {gridData: nextProps.gridData};
        } else
            return null;
    }

    render() {
        let tableHeaderStyle = Object.assign({}, styles.headerTable ? styles.headerTable : {}, this.props.style);
        let tableMainStyle = Object.assign({}, styles.mainTable ? styles.mainTable : {}, this.props.style);

        let toolbarParams = Object.assign({

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
            }, (this.props.toolbarParams ? this.props.toolbarParams : {})
        );

        // примем в зачет переданные стили
        styles = {...styles, ...this.props.style};
        return (
            <div style={styles.main}>
                {this.props.showToolBar ?
                    <ToolbarContainer
                        ref='grid-toolbar-container'
                        position={'left'}>
                        <GridButtonAdd
                            show={toolbarParams.btnAdd.show}
                            onClick={this.handleGridBtnClick}
                            value={'Lisa'}
                            ref="grid-button-add"/>
                        <GridButtonEdit
                            show={toolbarParams.btnEdit.show}
                            onClick={this.handleGridBtnClick}
                            value={'Muuda'}
                            ref="grid-button-edit"/>
                        <GridButtonDelete
                            show={toolbarParams.btnDelete.show}
                            onClick={this.handleGridBtnClick}
                            value={'Kustuta'}
                            ref="grid-button-delete"/>

                    </ToolbarContainer> : null}

                <div style={styles.header}>
                    <table ref="dataGridTable" style={tableHeaderStyle} onKeyPress={this.handleKeyDown}>
                        <tbody>
                        <tr>
                            {this.prepareTableHeader()}
                        </tr>
                        </tbody>
                    </table>
                </div>
                <div style={styles.wrapper}>
                    <table style={tableMainStyle} tabIndex="1" onKeyDown={this.handleKeyDown}
                           onKeyPress={this.handleKeyDown}>
                        <tbody>
                        <tr style={{visibility: 'collapse'}}>
                            {this.prepareTableHeader(true)}
                        </tr>
                        {this.prepareTableRow()}
                        {
                            this.props.subtotals && this.props.subtotals.length ?
                                <tr>
                                    {this.prepareTableFooter()}
                                </tr>
                                : null
                        }

                        </tbody>
                    </table>

                </div>
                <ModalPageDelete
                    show={this.state.isDelete}
                    modalPageBtnClick={this.modalDeletePageBtnClick.bind(this)}>
                </ModalPageDelete>

            </div>
        )
            ;

    } // render


    modalDeletePageBtnClick(btnEvent) {
        //close modalpage
        this.setState({isDelete: false});

        if (btnEvent === 'Ok' && this.props.handleGridBtnClick) {
            this.props.handleGridBtnClick('delete',
                this.state.activeRow,
                this.state.gridData.length ? this.state.gridData[this.state.activeRow].id : 0,
                this.props.docTypeId ? this.props.docTypeId : '');
        }
    }

    /**
     * обработчика сабытия клика по кнопки панели грида
     * @param btnName
     * @returns {*}
     */
    handleGridBtnClick(btnName) {

        let activeRow = this.state.activeRow;

        let id = this.state.gridData.length ? this.state.gridData[activeRow].id : 0;

        let docTypeId = this.props.docTypeId ? this.props.docTypeId : '';

        if ((btnName === 'delete' || btnName === 'Kustuta') && !this.state.isDelete) {
            // should open modal page and ask confirmation
            return this.setState({isDelete: true});
        }

        if (this.props.handleGridBtnClick) {
            this.props.handleGridBtnClick(btnName, activeRow, id, docTypeId);
        }
    }

    /**
     * ищем индех в массиве данных
     */
    getGridRowIndexById() {
        let index = 0;

        if (this.state.value) {
            index = this.state.gridData.findIndex(row => row.id === this.state.value);
            index = index > -1 ? index : 0;
        }
        return index;
    }

    /**
     * отрабатывает событи клика по ячейке
     * @param idx
     */
    handleCellClick(idx, columnId) {
        if (this.state.gridData.length > 0) {
            let action = this.props.onChangeAction || null;

            let docId = this.state.gridData[idx].id;
            const gridData = {...this.state.gridData};

            // Отработает клик по колонки селект для выбора массива записей
            if (this.state.isSelect && columnId == 'select') {
                // уже выбран, надо исключить
                gridData[idx].select = !gridData[idx].select;
            }

            // если поле не отмечено как readOnly то сл. действие не должно происходить
            if (columnId) {
                let column = this.props.gridColumns.filter((row) => row.id == columnId);
                if (column
                    && column.length
                    && !column[0].readOnly
                    && this.props.isForUpdate
                    && gridData[idx][columnId] !== null
                    && gridData[idx][columnId] !== undefined) {

                    // value changed
                    gridData[idx][columnId] = !gridData[idx][columnId];
                }
            }

            this.setState({
                gridData: gridData,
                activeRow: idx,
                value: docId,
            }, () => {
                let value = this.state.gridData[idx][columnId];
                if (this.props.onClick) {
                    this.props.onClick(action, docId, idx, columnId, value);
                }
            });
        }

    }

    /**
     * обработчик для двойного клика по ячейке
     * @param idx
     */
    handleCellDblClick(idx) {
        // отметим активную строку и вызовен обработчик события dblClick
        this.handleCellClick(idx, null);
        if (this.props.onDblClick) {
            this.props.onDblClick();
        }
    }

    /**
     * Отработает клик по заголовку грида (сортировка)
     * @param name - наименование колонки
     */
    handleGridHeaderClick(name) {
        if (name === 'select' || name === 'row_id') {
            // виртуальная колонка
            // меняем значение выбрано на наоборот

            if (this.state.gridData.length > 0 && name === 'select') {
                let data = this.state.gridData;
                data.forEach(row => {
                   row.select =  !row.select;
                });
                this.setState({gridData: data});
            }
            return;
        }

        let sort = this.state.sort;
        if (sort.name === name) {
            sort.direction = sort.direction === 'asc' ? 'desc' : 'asc';
        } else {
            sort = {
                name: name,
                direction: 'asc'
            }
        }

        let sortBy = [{column: sort.name, direction: sort.direction}];

        this.setState({
            activeColumn: name,
            sort: sort
        });

        if (this.props.onHeaderClick) {
            this.props.onHeaderClick(sortBy);
        }

    }

    /**
     * Обработчик на событие - нажитие стрелки вниз
     * @param e
     */
    handleKeyDown(e) {
        // реакция на клавиатуру
        let rowIndex = this.state.activeRow;
        switch (e.which) {
            case 40:
                // вниз, увеличим активную строку на + 1
                rowIndex++;

                if (this.state.gridData.length < rowIndex) {
                    // вернем прежнее значение
                    rowIndex = this.state.activeRow
                }
                break;
            case 38:
                // вниз, увеличим активную строку на - 1
                rowIndex--;
                rowIndex = rowIndex < 0 ? 0 : rowIndex;
                break;
        }
        this.setState({
            activeRow: rowIndex
        });
    }

    /**
     * Готовит строку для грида
     */
    prepareTableRow() {
        let activeRow = this.getGridRowIndexById();

        return this.state.gridData.map((row, rowIndex) => {
            let objectIndex = 'tr-' + rowIndex;

            let gridColumns = this.props.gridColumns.map(row => {
                if (row.id === 'select' && this.props.isSelect) {
                    row.show = true;
                }

                return row;
            });

            return (<tr
                ref={objectIndex}
                onClick={this.handleCellClick.bind(this, rowIndex, null)}
                onDoubleClick={this.handleCellDblClick.bind(this, rowIndex)}
                onKeyDown={this.handleKeyDown.bind(this)}
                style={Object.assign({}, styles.tr, activeRow === rowIndex ? styles.focused : {})}
                key={objectIndex}>
                {
                    gridColumns.map((column, columnIndex) => {
                        // назначим символы для отображения логических данных
                        let boolValueYes = column.boolSumbolYes ? column.boolSumbolYes : styles.boolSumbol['yes'].value || null;
                        let boolValueNo = column.boolSumbolNo ? column.boolSumbolNo : styles.boolSumbol['no'].value || null;
                        let boolValueNull = column.boolSumbolNull ? column.boolSumbolNull : styles.boolSumbol['null'] ? styles.boolSumbol['null'].value : null;

                        // приведем значение value к заданому типу для параметра hideEmptyValue
                        let fixedValue = column.type && column.type == "integer" ? Number(row[column.id]) : row[column.id];

                        let cellIndex = 'td-' + rowIndex + '-' + columnIndex;

                        let display = (isExists(column, 'show') ? column.show : true),
                            width = isExists(column, 'width') ? column.width : '100%',
                            style = Object.assign({}, styles.td, !display ? {display: 'none'} : {}, {width: width});

                        // проверим на заданный цвет
                        if (styles.boolColour && column.type && column.type === 'boolean') {

                            style = Object.assign(style,
                                {backgroundColor: !!row[column.id] ? styles.boolColour.yes : styles.boolColour.no},
                                {color: !!row[column.id] ? styles.boolSumbol['yes'].color : styles.boolSumbol['no'].color}
                            );
                        }

                        // если задан фон в конфиге грида
                        if (column.yesBackgroundColor && (!!row[column.id] || row[column.id] == 'Viga')) {
                            style = {...style, backgroundColor: column.yesBackgroundColor};
                        }

                        // Ок, Viga для  рапорта об исполнениее
                        if (column.noBackgroundColor && (!row[column.id] || row[column.id] == 'Ok')) {
                            style = {...style, backgroundColor: column.noBackgroundColor};
                        }

                        if (column.nullBackgroundColor && row[column.id] == null) {
                            style = {...style, backgroundColor: column.nullBackgroundColor};
                        }
                        // цвет, при значении NULL
                        if (styles.td && styles.td.nullColour && row[column.id] == null) {
                            style = Object.assign(style,
                                {backgroundColor: styles.td.nullColour}
                            );
                        }

                        // кастомное обработка стилей на клетку
                        if (this.props.custom_styling) {
                            let customeStyle = this.props.custom_styling(column, row);
                            style = {...style, ...customeStyle};
                        }

                        // оберем для конкретного поля параметр hideEmptyValue

                        let isHideEmptyValue = column.hideEmptyValue ? column.hideEmptyValue : false;

                        if (column.hideEmptyValue && row['nom_id'] && row['nom_id'] == 999999999) {
                            isHideEmptyValue = false;
                        }

                        return (
                            <td style={style}
                                ref={cellIndex}
                                key={cellIndex}
                                align={column.type && column.type === 'boolean' ? 'center' : 'left'}
                                onClick={this.handleCellClick.bind(this, rowIndex, column.id)}
                            >
                                {column.type && column.type === 'boolean' ?
                                    <span>{!!row[column.id] ?
                                        boolValueYes : (row[column.id] == null ?
                                            boolValueNull : boolValueNo)}</span> :
                                    isHideEmptyValue && !fixedValue ? null : row[column.id]}
                            </td>
                        );
                    })
                }

            </tr>);
        }, this);
    }

    /**
     * Готовит компонент итоговая строка грида
     * @param isHidden - колонка будет скрыта
     */
    prepareTableFooter(isHidden) {
        return (
            this.props.gridColumns.map((column, index) => {
                let headerIndex = 'td-' + index;

                let headerStyle = 'td';

                let display = (isExists(column, 'show') ? column.show : true),
                    width = isExists(column, 'width') ? column.width : '100%',
                    style = Object.assign({}, styles[headerStyle], !display ? {display: 'none'} : {}, {width: width});

                let subIndex = this.props.subtotals.indexOf(column.id);
                let total;
                if (subIndex > -1) {
                    total = this.getSum(column.id, column.type && column.type == 'integer' ? 0 : 2);
                }

                // установить видимость
                return (<td
                    style={style}
                    ref={headerIndex}
                    key={headerIndex}
                >
                    <span>{total}</span>
                </td>)
            }, this)

        )
    }

    /**
     * Готовит компонент заголовок грида
     * @param isHidden - колонка будет скрыта
     */
    prepareTableHeader(isHidden) {
        // если есть опция выбор, то добавим в массив колонку с полем ticked
        const gridColumns = this.props.gridColumns.map(row => {
            if (row.id === 'select') {
                row.show = this.props.isSelect;
            }
            return row;
        });

        return gridColumns.map((column, index) => {
            let headerIndex = 'th-' + index + column.id;

            let headerStyle = isHidden ? 'thHidden' : 'th';

            // проверка на стиль заголовка, на фонт
            let fontColor = {
                color: column.showBold && styles[headerStyle].boldColor ? styles[headerStyle].boldColor : styles[headerStyle].color
            };

            let display = (isExists(column, 'show') ? column.show : true),
                width = isExists(column, 'width') ? column.width : '100%',
                style = Object.assign({}, styles[headerStyle], !display ? {display: 'none'} : {}, {width: width}, fontColor),
                activeColumn = this.state.activeColumn,
                iconType = this.state.sort.direction,
                imageStyleAsc = Object.assign({}, styles.image, (activeColumn === column.id && iconType === 'asc') ? {} : {display: 'none'}),
                imageStyleDesc = Object.assign({}, styles.image, (activeColumn === column.id && iconType === 'desc') ? {} : {display: 'none'});

            // установить видимость
            return (<th
                style={style}
                ref={headerIndex}
                key={headerIndex}
                onClick={this.handleGridHeaderClick.bind(this, column.id)}>
                <span>{column.name}</span>
                {isHidden ? <img ref="imageAsc" style={imageStyleAsc} src={styles.icons['asc']} alt={'asc'}/> : null}
                {isHidden ?
                    <img ref="imageDesc" style={imageStyleDesc} src={styles.icons['desc']} alt={'desc'}/> : null}
            </th>)
        }, this);
    }

    /**
     * расчет итогов
     * @param columnField
     * @param dec
     * @returns {string}
     */
    getSum(columnField, dec) {
        let total = 0;
        let summa = 0;
        if (this.state.gridData.length) {
            this.state.gridData.forEach(row => {
                summa = row[columnField] && !isNaN(row[columnField]) ? Number(row[columnField]) : (row[columnField] ? 1 : 0);
                total = total + Number(summa)
            });
        }

        return total.toFixed(dec ? dec : 0);
    }

}


DataGrid.propTypes = {
    gridColumns: PropTypes.arrayOf(
        PropTypes.shape({
            id: PropTypes.string.isRequired,
            name: PropTypes.string.isRequired,
            width: PropTypes.string,
            show: PropTypes.bool,
            type: PropTypes.oneOf(['text', 'number', 'integer', 'date', 'string', 'select', 'boolean'])
        })).isRequired,
    gridData: PropTypes.array.isRequired,
    onChangeAction: PropTypes.string,
    onClick: PropTypes.func,
    onDblClick: PropTypes.func,
    onHeaderClick: PropTypes.func,
    custom_styling: PropTypes.func,
    activeRow: PropTypes.number,
    handleGridCellClick: PropTypes.func,
    showToolBar: PropTypes.bool,
    subtotals: PropTypes.array
};

DataGrid.defaultProps = {
    gridColumns: [],
    gridData: [],
    style: {},
    showToolBar: false,
    isForUpdate: false,
    custom_styling: null,
    subtotals: []
};

module.exports = DataGrid;