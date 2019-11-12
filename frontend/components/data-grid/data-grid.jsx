'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('./data-grid-styles'),
    ToolbarContainer = require('./../toolbar-container/toolbar-container.jsx'),
    GridButtonAdd = require('./../button-register/button-register-add/button-register-add.jsx'),
    GridButtonEdit = require('./../button-register/button-register-edit/button-register-edit.jsx'),
    GridButtonDelete = require('./../button-register/button-register-delete/button-register-delete.jsx'),
    ModalPageDelete = require('./../../components/modalpage/modalpage-delete/modalPage-delete.jsx'),

    keydown = require('react-keydown');

const _ = require('lodash');

//const    KEYS = [38, 40]; // мониторим только стрелки вверх и внизх

const isExists = (object, prop) => {
    let result = false;
    if (prop in object) {
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
            isSelect: this.props.isSelect ? true : false,
        };

        this.handleGridHeaderClick = this.handleGridHeaderClick.bind(this);
        this.handleCellDblClick = this.handleCellDblClick.bind(this);
        this.handleKeyDown = this.handleKeyDown.bind(this);
        this.prepareTableRow = this.prepareTableRow.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
        this.getGridRowIndexById = this.getGridRowIndexById.bind(this);
    }


    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        return nextProps;
        if (JSON.stringify(nextProps.gridData) !== JSON.stringify(prevState.gridData) ||
         //   (nextProps.value && nextProps.value !== prevState.value) ||
            nextProps.gridData.length !== prevState.gridData.length ||
            nextProps.isSelect !== prevState.isSelect) {
            return {gridData: nextProps.gridData};
        } else
            return null;
    }

    render() {
        let tableStyle = Object.assign({}, styles.headerTable, this.props.style);

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

        return (
            <div style={styles.main}>
                {this.props.showToolBar ?
                    <ToolbarContainer
                        ref='grid-toolbar-container'
                        position={'left'}>
                        <GridButtonAdd
                            show={toolbarParams.btnAdd.show}
                            onClick={this.handleGridBtnClick}
                            ref="grid-button-add"/>
                        <GridButtonEdit
                            show={toolbarParams.btnEdit.show}
                            onClick={this.handleGridBtnClick}
                            ref="grid-button-edit"/>
                        <GridButtonDelete
                            show={toolbarParams.btnDelete.show}
                            onClick={this.handleGridBtnClick}
                            ref="grid-button-delete"/>

                    </ToolbarContainer> : null}

                <div style={styles.header}>
                    <table ref="dataGridTable" style={tableStyle} onKeyPress={this.handleKeyDown}>
                        <tbody>
                        <tr>
                            {this.prepareTableHeader()}
                        </tr>
                        </tbody>
                    </table>
                </div>
                <div style={styles.wrapper}>
                    <table style={tableStyle} tabIndex="1" onKeyDown={this.handleKeyDown}
                           onKeyPress={this.handleKeyDown}>
                        <tbody>
                        <tr style={{visibility: 'collapse'}}>
                            {this.prepareTableHeader(true)}
                        </tr>
                        {this.prepareTableRow()}
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
                _.size(this.state.gridData) ? this.state.gridData[this.state.activeRow].id : 0,
                this.props.docTypeId ? this.props.docTypeId : '');
        }
    }

    handleGridBtnClick(btnName) {
        let activeRow = this.state.activeRow;

        let id = _.size(this.state.gridData) ? this.state.gridData[activeRow].id : 0;

        let docTypeId = this.props.docTypeId ? this.props.docTypeId : '';

        if (btnName === 'delete' && !this.state.isDelete) {
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
    handleCellClick(idx) {
        if (this.state.gridData.length > 0) {
            let action = this.props.onChangeAction || null;

            let docId = this.state.gridData[idx].id;
            const gridData = {...this.state.gridData};

            if (this.state.isSelect) {
                // уже выбран, надо исключить
                gridData[idx].select = !gridData[idx].select;
            }

            this.setState({
                gridData: gridData,
                activeRow: idx,
                value: docId,
            });

            if (this.props.onClick) {
                this.props.onClick(action, docId, idx);
            }
        }

    }

    /**
     * обработчик для двойного клика по ячейке
     * @param idx
     */
    handleCellDblClick(idx) {
        // отметим активную строку и вызовен обработчик события dblClick
        this.handleCellClick(idx);
        if (this.props.onDblClick) {
            this.props.onDblClick();
        }
    }

    /**
     * Отработает клик по заголовку грида (сортировка)
     * @param name - наименование колонки
     */
    handleGridHeaderClick(name) {
        if (name === 'valitud') {
            // виртуальная колонка
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
                onClick={this.handleCellClick.bind(this, rowIndex)}
                onDoubleClick={this.handleCellDblClick.bind(this, rowIndex)}
                onKeyDown={this.handleKeyDown.bind(this)}
                style={Object.assign({}, styles.tr, activeRow === rowIndex ? styles.focused : {})}
                key={objectIndex}>
                {
                    gridColumns.map((column, columnIndex) => {
                        let cellIndex = 'td-' + rowIndex + '-' + columnIndex;

                        let display = (isExists(column, 'show') ? column.show : true),
                            width = isExists(column, 'width') ? column.width : '100%',
                            style = Object.assign({}, styles.td, !display ? {display: 'none'} : {}, {width: width});

                        return (
                            <td style={style} ref={cellIndex} key={cellIndex}>
                                {typeof row[column.id] === 'boolean' && row[column.id] ?
                                    <span>&#9745;</span> : row[column.id]}
                            </td>
                        );
                    })
                }

            </tr>);
        }, this);
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
            let headerIndex = 'th-' + index;

            let headerStyle = 'th';
            if (isHidden) {
                headerStyle = 'thHidden';
            }

            let display = (isExists(column, 'show') ? column.show : true),
                width = isExists(column, 'width') ? column.width : '100%',
                style = Object.assign({}, styles[headerStyle], !display ? {display: 'none'} : {}, {width: width}),
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
}

DataGrid.propTypes = {
    gridColumns: PropTypes.arrayOf(
        PropTypes.shape({
            id: PropTypes.string.isRequired,
            name: PropTypes.string.isRequired,
            width: PropTypes.string,
            show: PropTypes.bool,
            type: PropTypes.oneOf(['text', 'number', 'integer', 'date', 'string', 'select'])
        })).isRequired,
    gridData: PropTypes.array.isRequired,
    onChangeAction: PropTypes.string,
    onClick: PropTypes.func,
    onDblClick: PropTypes.func,
    onHeaderClick: PropTypes.func,
    activeRow: PropTypes.number,
    showToolBar: PropTypes.bool
};

DataGrid.defaultProps = {
    gridColumns: [],
    gridData: [],
    style: {},
    showToolBar: false
};

module.exports = DataGrid;
