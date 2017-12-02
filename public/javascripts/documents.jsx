
//var ReactDOM = require('react-dom');

var MyGrid = React.createClass({
    getInitialState: function() {
        return {
            gridColumns: this.props.gridColumns,
            gridData: this.props.gridData,
            clicked: 0
        };
    },

    handleCellClick: function(idx) {
        this.setState({
            clicked: idx
        });
    },
    render: function() {
        var gridRows = this.state.gridData;
        var gridColumns = this.state.gridColumns;
        var clickedItem = this.state.index;

        var className = 'th';

        return (
            <table>
                <tbody>
                    <tr>
                        {columns.map(function(column, index) {
                            console.log(column.id);
                            var gridStyle = {
                                width:column.width
                                };
                            className = 'th-'+(column.id);
                            return <th  style={gridStyle} className={className} key={'th-'+index}>{column.name}</th>
                            })
                            }
                    </tr>
                </tbody>
                <tbody>
                    {
                        gridRows.map(function(row, index) {
                            var myClass = 'notFocused';
                            var myKey = 0;
                            if  (clickedItem == index){
                                myClass = 'focused'; // подсветим выбранную строку
                                };
                            return (
                            <tr onClick={this.handleCellClick.bind(this,index)} className={myClass} key={'doc-'+index}>
                                {gridColumns.map(function(cell, index) {
                                    return (
                                    <td key={'td'+index}>{row[cell.id]}</td>
                                        )
                                    })}
                            </tr>
                                );

                            }, this)
                        }
                </tbody>
            </table>
        )
    }
});


var MyComp = React.createClass({
    getInitialState: function() {
        return {
            sourceArray:this.props.sourceArray,
            isChecked: false,
            clicked: 0
        }
    },

    handleLiClick: function(idx) {
        var myArray = this.state.sourceArray;
        //ставим метку
        // сохраняем состояние

        this.setState({
            clicked: idx
        });

    },

    handleButtonClick: function() {
        // при клике показываем или скрывает компонент
        this.setState({
            isChecked: !this.state.isChecked
        });
    },
    render: function() {
        var myArray = this.state.sourceArray;
        var myStyle = this.state.isChecked ? 'none' : 'block'; // прячет список
        var myGridStyle = 'block';
        var clickedItem = this.state.index;

        myArray = myArray.map(function(item, index) {
            var myClass = 'liDocLibs';
            var lib =  JSON.parse(item);

            if  (clickedItem == index){
                myClass = myClass + ' focused'; // подсветим выбранную строку
            };

            return React.createElement('li', {
                    key: 'lib-'+index,
                    className: (myClass),
                    style:{display:myStyle},
                    onClick:this.handleLiClick.bind(this,index)
                },lib.nimetus);
        }, this);

        var root = React.createElement('ul',null, myArray);
        var docLibsDiv = React.createElement('div',{className:'treeDocs', style:{display:myStyle}, id:'treeDocs'},root);
        var buttonValue = this.state.isChecked ? '+' : '-';
        return (
            <div>
                <div id="treeToolBar">
                    <input type="button" value = {buttonValue} onClick={this.handleButtonClick}/>
                </div>
                {docLibsDiv}
            </div>

        );
    }
});

//var myArray = JSON.parse(docs);

var rows = [
    {id:1, name:"row1", text:"Text 1"},
    {id:2, name:"row2", text:"Text 2"},
    {id:3, name:"row3", text:"Text 3"},
    {id:4, name:"row4", text:"Text 4"}
];

var columns = [
    {id:"id", name:"id", width: "50px"},
    {id:"name", name:"name", width: "300px"},
    {id:"text", name:"text", width: "400px"}
];

//var gridData = JSON.parse(gridData);
//var gridConfiguration = JSON.parse(gridConf);

//console.log('gridConfiguration' + gridConfiguration + typeof gridConfiguration);
//  gridData={rows} gridColumns={columns}

React.render(
    <div>
        <div id="gridToolBar">ToolBar</div>
        <MyGrid gridData={rows} gridColumns={columns}/>
    </div>,
    document.getElementById('document'));
