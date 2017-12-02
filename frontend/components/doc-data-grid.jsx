var React = require('react'),
    flux = require('fluxify'),
    GridButton = require('./mybutton');

var MyCell = React.createClass({
    getInitialState: function () {
        return {
            value: this.props.value, editable: false, readOnly: this.props.readOnly, disabled: false
        }
    },

    componentWillReceiveProps: function () {
        this.setState({value: this.props.value})
    },

    componentDidMount: function () {
        var self = this;

        flux.stores.docStore.on('change:gridCellEdited', function (newValue, previousValue) {
            // отслеживает момент перехода на другую ячейку
            if (newValue !== self.props.id) {
                var cell = self.refs['cell-' + self.props.id];
                if (cell) {
                    self.setState({editable: false}); // убираем режим редактирования
                }
            }
        });

        flux.stores.docStore.on('change:edited', function (newValue, previousValue) {
            // отслеживает режим редактирования
            var data = flux.stores.docStore,
                gridData = eval('data.' + self.props.gridDataSource);
            if (newValue !== previousValue && gridData.length > 0) {
                self.setState({readOnly: !newValue});
            }
        });


    },

    handleClick: function () {
        var value = !this.state.editable;
        // отработаем редактирование
        flux.doAction('gridCellEditedChange', this.props.id); // закроем редактирование в других ячейках
        this.setState({editable: value});

    },

    onChange: function (e, bindToCell) {
        // отрабатывает изменение состояния ячейки и пишет в хранилще
        var value = e.target.value,
            data = flux.stores.docStore,
            gridData = eval('data.' + this.props.gridDataSource) || [],
            cellName = bindToCell ? bindToCell : this.props.source;

        this.setState({value: value});

        // пишем состояние в хранилище
        if (gridData.length > 0) {
            var cellValue = gridData[this.props.rowId][cellName];

            gridData[this.props.rowId][cellName] = value;
            flux.doAction('detailsChange', gridData);
            flux.doAction('gridCellEditedChange', this.props.id); // закроем редактирование в других ячейках
        }

    },

    handleKeyPress: function (e) {
        var key = e.which || e.keyCode;
        if (key == 13) {
            // выходим из редактирования
            this.setState({editable: false});
        }
    },
    render: function () {
        var isEdit = (flux.stores.docStore.edited && !this.state.disabled) ? true : false,
            cell = this.props.cell, // параметры ячейки
            isReadOnly = !flux.stores.docStore.edited,
//            cellType = cell.type || 'span'; // находится ли док в режиме редактирования
            cellType = 'span'; // находится ли док в режиме редактирования

        isReadOnly = cell.readOnly ? true : isReadOnly; // поправка на свойство ячейки, доступна ли она редактированию
//            className = 'form-widget'; //+ t his.state.editable? ' focused': '';
        isReadOnly = true;
        var EditElement = <span onClick={this.handleClick} className={this.props.className}>{this.props.value}</span>;
        if (isEdit) {
            /*
             switch (cellType) {
             case 'text':
             EditElement = <input type='text' readOnly={isReadOnly} value={this.state.value} style={{width:'100%'}}
             onChange={this.onChange} onKeyPress={this.handleKeyPress}/>
             break;
             case 'number':
             EditElement = <input type='number' readOnly={isReadOnly} value={this.state.value} style={{width:'100%'}}
             onChange={this.onChange} onKeyPress={this.handleKeyPress}/>
             break;
             case 'select':
             EditElement = <Select  name={cell.valueFieldName} libs={cell.dataSet} value={this.state.value} defaultValue = {this.state.value} collId = {cell.id} onChange={this.onChange}/>
             break;
             default:
             <span>{this.state.value}</span>
             }
             */
        }

        return (
            <td ref={'cell-' + this.props.id} className={this.props.className} style={{width:cell.width}}>
                {EditElement}
            </td>
        )
    }
})

var DataGrid = React.createClass({
    getInitialState: function () {
        return {
            gridColumns: this.props.gridColumns,
            gridData: this.prepaireGridData(this.props.gridData),
            edited: false,
            clicked: 0
        };
    },
    getDefaultProps: function () {
        return {
            GridRowEdit: null
        };
    },
    componentDidMount: function () {
        var self = this;

        flux.stores.docStore.on('change:docId', function (newValue, previousValue) {
            // отслеживает режим создания нового документа

            var data = flux.stores.docStore,
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

    },

    handleCellClick: function (idx) {
        flux.doAction('gridRowIdChange', idx); // отметим в хранилище номер строки
        this.setState({
            clicked: idx
        });
        var rowId = flux.stores.docStore.gridRowId;
    },

    delRow: function (index) {
        // удалим строку заданную строку или все, если индекс не задан
        var gridData = this.state.gridData,
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

    },

    newRow: function () {
        //вернет новую строку для грида, на основе шаблона

        var gridColumns = this.props.gridColumns,
            gridData = flux.stores.docStore.details,
            row = new Object();

        for (var i = 0; i < gridColumns.length; i++) {
            var field = gridColumns[i].id;
            row[field] = '';
        }
        return row;
    },

    prepaireGridData: function (sourceData) {
        var gridData = [];
        gridData = sourceData.map(function (row) {
            // получаем чистую строку
            var newRow = this.newRow();
            // пройдем по новой строке и заполним ее поля значениями из источника

            for (var key in newRow) {
                newRow[key] = row[key];
            }
            return newRow; // вернем сформированную новую строку
        }, this);
        return gridData;
    },

    deleteRow: function () {
        // удаление строки из грида
        var rowIndex = flux.stores.docStore.gridRowId;
        this.delRow(rowIndex);
    },

    addRow: function () {
        // добавит в состояние новую строку
        var newRow = this.newRow(),
            gridData = this.state.gridData,
            details = flux.stores.docStore.details;

        newRow.id = 'NEW' + Math.random(); // генерим новое ид
//        gridData.push(newRow);
//        this.setState({edited: true, clicked: gridData.length});

        // здесь вставить строку в хранилище
//        details.push(newRow);
//        flux.doAction('detailsChange', details); // пишем изменения в хранилище
        flux.doAction('gridRowIdChange', -1); // отметим в хранилище номер строки

  //      this.setState({gridData: gridData});

        // откроем модальное окно для редактирования
        this.props.handleGridRow('ADD', newRow);
    },

    editRow: function () {
        // добавит в состояние новую строку
        var gridData = this.state.gridData,
            details = flux.stores.docStore.details,
            row = details[flux.stores.docStore.gridRowId]

        this.props.handleGridRow('EDIT',row ); // редактирование строки в модальном окне

    },

    render: function () {
        var gridStyle = {
            width: '100px'
        };
        var className = 'th';
        var gridRows = this.state.gridData,
            gridColumns = this.props.gridColumns,
            clickedItem = this.state.index,
            isReadOnly = this.props.readOnly,
            cellId = 0,
            gridDataSource = this.props.source;

        return (
            <div>
                {!isReadOnly ?
                    <div>
                        <GridButton onClick={this.addRow} buttonValue="Add row"/>
                        <GridButton onClick={this.editRow} buttonValue="Edit row"/>
                        <GridButton onClick={this.deleteRow} buttonValue="Delete row"/>
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
                        var myClass = 'notFocused',
                            rowId = index;
                        if (clickedItem == index) {
                            myClass = 'focused'; // подсветим выбранную строку
                        }
                        ;
                        return (
                            <tr onClick={this.handleCellClick.bind(this,index)} className={myClass} key={'tr-'+index}>
                                {gridColumns.map(function (cell, index) {
                                    gridStyle.width = cell.width;
                                    var className = 'show';
                                    if (cell.show) {
                                        // показать ил скрыть колонку? испллдьзуем класс. Должен быть прописан в css
                                        className = 'show';
                                    } else {
                                        className = 'hide';
                                    }

                                    return (
                                        <MyCell cell={cell}
                                                source={cell.id}
                                                className={className}
                                                rowId={rowId}
                                                gridDataSource={gridDataSource}
                                                readOnly={isReadOnly}
                                                style={gridStyle}
                                                value={row[cell.id]}
                                                key={index} id={cellId++}/>
                                    )
                                })}
                            </tr>);
                    }, this)}
                    </tbody>
                </table>
            </div>
        )
    }
});

module.exports = DataGrid;
