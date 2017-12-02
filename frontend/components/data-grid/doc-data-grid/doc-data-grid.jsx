
const PropTypes = require('prop-types');

const React = require('react'),
    flux = require('fluxify'),
    GridButtonAdd = require('../../button-register/button-register-add/button-register-add.jsx'),
    GridButtonEdit = require('../../button-register/button-register-edit/button-register-edit.jsx'),
    GridButtonDelete = require('../../button-register/button-register-delete/button-register-delete.jsx'),
    GridCell = require('./grid-cell/grid-cell.jsx');

class DataGrid extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            gridColumns: this.props.gridColumns,
            gridData: this.prepaireGridData(this.props.gridData),
            edited: false,
            clicked: 0
        };
        this.addRow = this.addRow.bind(this);
        this.editRow = this.editRow.bind(this);
        this.deleteRow = this.deleteRow.bind(this);
    }

    componentDidMount() {
        let self = this;

        flux.stores.docStore.on('change:docId', function (newValue, previousValue) {
            // отслеживает режим создания нового документа

            let data = flux.stores.docStore,
                gridData = eval('data.' + self.props.source);
            if (newValue == 0) {
                gridData = self.delRow(null);
                flux.doAction('detailsChange', gridData);
            }
        });
        // Listen gridData changes and then callbacks for row data changes
        flux.stores.docStore.on('change:details', function (newData, oldData) {
            if (newData.length > 0 && oldData !== newData) {
                self.setState({gridData: newData});
            }
        });

    }

    handleCellClick(idx) {
        flux.doAction('gridRowIdChange', idx); // отметим в хранилище номер строки
        this.setState({
            clicked: idx
        });
        let rowId = flux.stores.docStore.gridRowId;
    }

    delRow(index) {
        // удалим строку заданную строку или все, если индекс не задан
        let gridData = this.state.gridData,
            start = 1,
            finish = gridData.length;

        if (index || index == 0) {
            start = index;
            finish = 1;
        }
//        gridData.splice(start, finish);
        gridData = gridData.filter(function (value, index) {
            if (index < start || index > (start + finish)) {
                return value;
            }
        })
        this.setState({gridData: gridData});
        // сохраним изменения
        flux.doAction('detailsChange', gridData)

    }

    newRow() {
        //вернет новую строку для грида, на основе шаблона

        let gridColumns = this.props.gridColumns,
            gridData = flux.stores.docStore.details,
            row = new Object();

        for (let i = 0; i < gridColumns.length; i++) {
            let field = gridColumns[i].id;
            row[field] = '';
        }
        return row;
    }

    prepaireGridData(sourceData) {
        let gridData = [];
        gridData = sourceData.map(function (row) {
            // получаем чистую строку
            let newRow = this.newRow();
            // пройдем по новой строке и заполним ее поля значениями из источника

            for (let key in newRow) {
                newRow[key] = row[key];
            }
            return newRow; // вернем сформированную новую строку
        }, this);
        return gridData;
    }

    deleteRow() {
        // удаление строки из грида
        let rowIndex = flux.stores.docStore.gridRowId;
        this.delRow(rowIndex);
    }

    addRow() {
        // добавит в состояние новую строку
        let newRow = this.newRow(),
            gridData = this.state.gridData,
            details = flux.stores.docStore.details;

        newRow.id = 'NEW' + Math.random(); // генерим новое ид

        flux.doAction('gridRowIdChange', -1); // отметим в хранилище номер строки

        // откроем модальное окно для редактирования
        this.props.handleGridRow('ADD', newRow);
    }

    editRow() {
        // добавит в состояние новую строку
        let gridData = this.state.gridData,
            details = flux.stores.docStore.details,
            row = details[flux.stores.docStore.gridRowId]

        this.props.handleGridRow('EDIT', row); // редактирование строки в модальном окне

    }

    render() {
        let gridStyle = {
                width: '100px'
            },
            className = 'th',
            gridRows = this.state.gridData,
            gridColumns = this.props.gridColumns,
            clickedItem = this.state.index,
            isReadOnly = this.props.readOnly,
            cellId = 0,
            gridDataSource = this.props.source;

        return (
            <div>
                {!isReadOnly ?
                    <div>
                        <GridButtonAdd onClick={this.addRow}/>
                        <GridButtonEdit onClick={this.editRow}/>
                        <GridButtonDelete onClick={this.deleteRow}/>
                    </div> : null}
                <table>
                    <tbody>
                    <tr>
                        {/*заголовок*/}
                        {gridColumns.map(function (column, index) {
                            gridStyle.width = column.width;
                            className = 'th-' + column.id;
                            if (column.show) {
                                // показать ил скрыть колонку
                                className = 'show';
                            } else {
                                className = 'hide';
                            }
                            return <th style={gridStyle} className={className} key={'th-' + index}
                                       scope="col">{column.name}</th>
                        })}
                    </tr>
                    {gridRows.map(function (row, index) {
                        let myClass = 'notFocused',
                            rowId = index;
                        if (clickedItem == index) {
                            myClass = 'focused'; // подсветим выбранную строку
                        }
                        ;
                        return (
                            <tr onClick={this.handleCellClick.bind(this, index)}
                                className={myClass} key={'tr-' + index}>
                                {gridColumns.map(function (cell, index) {
                                    gridStyle.width = cell.width;
                                    let className = 'show';
                                    if (cell.show) {
                                        // показать ил скрыть колонку? испллдьзуем класс. Должен быть прописан в css
                                        className = 'show';
                                    } else {
                                        className = 'hide';
                                    }

                                    return (
                                        <GridCell cell={cell}
                                                  source={cell.id}
                                                  className={className}
                                                  rowId={rowId}
                                                  gridDataSource={gridDataSource}
                                                  readOnly={isReadOnly}
                                                  style={gridStyle}
                                                  value={row[cell.id]}
                                                  key={index}
                                                  ref = {index}
                                                  id={cellId++}/>
                                    )
                                })}
                            </tr>);
                    }, this)}
                    </tbody>
                </table>
            </div>
        )
    }
}

DataGrid.propTypes = {
    gridColumns: PropTypes.array.isRequired,
    gridData: PropTypes.array.isRequired
}

DataGrid.defaultProps = {
    GridRowEdit: null,
    gridColumns: [],
    gridData: []
}

module.exports = DataGrid;
