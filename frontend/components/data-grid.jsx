'use strict';

const React = require('react'),
    flux = require('fluxify'),
    keydown = require('react-keydown'),
    KEYS = [ 38, 40]; // мониторим только стрелки вверх и внизх

/*
@keydown( 'enter' )
toggleHello() {
    console.log('enter');
},
*/


var DataGrid = React.createClass({
    displayName: 'DataGrid',
    getInitialState: function getInitialState() {

        return {
            gridColumns: this.props.gridColumns,
            gridData: this.props.gridData,
            clicked: 0
        };
    },


/*
    componentWillReceiveProps: function (nextProps) {
        /!*
         if (nextProps.gridData) {
         var docId =  localStorage['docsGrid'],
         index = this.getGridRowIndexById(docId);

         console.log('componentWillReceiveProps', index, docId);
         this.handleCellClick(index);
         }
         *!/
        const { keydown: { event } } = nextProps;
        if ( event ) {
            console.log('got event', event.which);
//            this.setState( { key: event.which } );
        }
    },
*/

    /*

     shouldComponentUpdate: function(nextProps, nextState) {
     // изменения будут отражаться только в случае если такие есть
     var returnValue = (JSON.stringify(nextState) !== JSON.stringify(this.state) );
     return returnValue;
     },
     */
    componentDidMount: function () {

/*
         console.log('grid componentDidMount',localStorage['docsGrid'] );

         // ищем последнюю строку
         if (this.state.clicked == 0) {
         // отметим последний отмеченный документ
         var docId =  localStorage['docsGrid'],
         index = this.getGridRowIndexById(docId);

         console.log('grid componentDidMount',docId,index );

         this.setState({clicked: index});
         }
*/

    },

    componentWillMount: function () {

        var self = this;
        // повесим обработчики


        flux.stores.docsStore.on('change:data', function (newValue, previousValue) {
            // данные изменились, меняем состояние
            // ищем последнюю строку
            // отметим последний отмеченный документ

 //           console.log('my grid on change list ', newValue, previousValue)

            if (newValue !== []) {
                var docId = localStorage['docsGrid'],
                    index = self.getGridRowIndexById(docId);

                self.setState({index: index});
            }

        })

    },

    getGridRowIndexById: function (docId) {
        // ищем индех в массиве данных
        var index = 0,
            data = this.props.gridData;
        if (docId) {
            for (let i = 0; i < data.length; i++) {
                let row = data[i];
                if (row && data[i]['id'] == docId) {
                    index = i;
                    break;
                }
            }
        }
        return index;
    },

    handleCellClick: function handleCellClick(idx) {
        // отрабатывает событи клика по ячейке
        this.setState({
            clicked: idx
        });

        if (this.props.gridData.length > 0) {
            var docId = this.props.gridData[idx].id;
 //           console.log('myGrid handleCellClick:', idx, docId, this.props.gridData);
            // сохраним в хранилище
            flux.doAction(this.props.onChangeAction, docId);
        }
    },

    handleCellDblClick: function () {
        // вызовет метод редактирования
        flux.doAction('Edit');
    },

    handleGridHeaderClick: function (name) {
        var sortBy = [{column: name, direction: 'asc'}];
        flux.doAction('sortByChange', sortBy);
    },

    handleKeyDown: function (e) {
        // реакция на клавиатуру
        console.log('handleKeyPress ', e, keyCode, e);
        /*
         if (keyDirection == 'Down') {
         this.setState({
         clicked: (this.state.clicked + 1)
         });
         }
         */

    },
    render: function render() {
        var gridRows = this.props.gridData; // статичны и приходят только из верхнего компонента
        var gridColumns = this.props.gridColumns;
        var clickedItem = this.state.index;

        var className = 'th',
            self = this;
        /*       onKeyDown: this.handleKeyPress('Down'),
         onDoubleClick: this.handleCellDblClick(),
         {onKeyDown = {this.handleKeyDown}}
         */
        return (<table ref="myGridRef"  onKeyDown = {this.handleKeyDown}
                      >
                    <tbody>
                    <tr>
                        {
                            gridColumns.map(function (column, index) {
                                var gridStyle = {
                                    width: column.width
                                };
                                className = 'th-' + column.id;
                                return <th
                                            style={gridStyle}
                                            className={className}
                                            key={'th-' + index}
                                            onClick={this.handleGridHeaderClick.bind(this, column.id)}
                                        >
                                            {column.name}
                                        </th>
                            }, this)}

                    </tr>
                    </tbody>
                    <tbody>
                    {
                        gridRows.map(function (row, index) {
                            var myClass = 'notFocused';
                            if (clickedItem == index) {
                                myClass = 'focused'; // подсветим выбранную строку
                            }
                            ;
                            return (<tr
                                onClick={this.handleCellClick.bind(this, index)}
                                onKeyDown = {this.handleKeyDown}
                                className={myClass}
                                key={'doc-' + index}>
                                {
                                    gridColumns.map(function (cell, index) {
                                           return (<td key={'td' + index}>
                                                   {row[cell.id]}
                                           </td>)
                                        })
                                }

                            </tr>)
                        }, this)
                    }
                    </tbody>
                </table>
        );

    }
});

module.exports = DataGrid;