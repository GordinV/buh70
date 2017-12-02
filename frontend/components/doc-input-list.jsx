'use strict';

const React = require('react'),
    flux = require('fluxify'),

    List = React.createClass({
        getInitialState: function () {
            return {
                readOnly: this.props.readOnly,
                disabled: this.props.disabled,
                data: this.props.data,
                clicked: 0
            }
        },

        getDefaultProps: function () {
            return {
                readOnly: true,
                data: [],
                disabled: false,
                title: '',
                name: 'My default List',
                className: ''
            }
        },

        /*  componentWillMount: ()=> {
         // создаем обработчик события на изменение docId. Если значение = 0 (добавляем новую запись, то просто очитка полей, иначе подгрузка данных
         let self = this;

         flux.stores.docStore.on('change:docId', function (newValue, previousValue) {
         if (newValue !== previousValue) {
         var data = flux.stores.docStore.data,
         value = data[self.props.name];
         if (newValue == 0) {
         // совый документ
         self.setState({value: 0});
         } else {
         self.setState({value: value});
         }
         }
         });

         flux.stores.docStore.on('change:edited', function (newValue, previousValue) {
         if (newValue !== previousValue) {
         self.setState({readOnly: !newValue, disabled: !newValue});
         }
         });

         flux.stores.docStore.on('change:libs', function (newValue, previousValue) {
         var vastus = JSON.stringify(newValue) !== JSON.stringify(previousValue);
         // will watch libs change (from server)
         var data = newValue.filter(function (item) {
         if (item.id === self.props.libs) {
         return item;
         }
         });

         if (data && data.length > 0) {
         self.setState({data: data[0].data});
         }
         });
         },
         */

        handleLiClick: function (index) {
            this.setState({
                clicked: index
            });
        },


        handleClickBtnDeleteExecutor: function (index) {
            let data = this.state.data;
            console.log('list btn delete', index);
        },

        handleClickBtnAddExecutor: function (index) {
            let data = this.state.data;
            console.log('list btn add', index);

        },

        componentWillReceiveProps: function(nextProps) {
            // при изменении срежима редактирования, поменяет состояние виджета
            this.setState({readOnly:nextProps.readOnly })
        },

        render: function () {

            let data = this.state.data || [],
                inputClassName = this.props.className || 'doc-input form-widget',
                inputReadOnly = this.state.readOnly || false,
                inputPlaceHolder = this.props.placeholder || this.props.name,
                Options = null;

            // создадим список значений
            if (data.length) {
                Options = data.map(function (item, index) {
                    let className = this.props.className;

                    if (typeof item == 'array') {
                        item = item[0];
                    }

                    if (this.state.index == index && !this.state.readOnly ) {
                        // выделим в списке значение, при условии, что режим редактирования это позволяет
                        className = className + ' focused';
                    }
                    return (
                        <li
                            key={Math.random()}
                            className={className}
                            onClick={this.handleLiClick.bind(this, index)}
                        >{item.name}
                        </li>
                    )
                }, this);
            }

            let widget = <ul
                name={this.props.name}
                style={{width: '100%', height: '100%'}}>
                {Options}
            </ul>;


            return <div className="form-widget">
                <div style={{display: "flex"}}>
                    <label style={{paddingRight: "5px"}} > {this.props.title}</label>
                    {this.state.readOnly ? null : <input type="button" value=" Add " onClick={this.handleClickBtnAddExecutor}/>}
                    {this.state.readOnly ? null : <input type="button" value = " Delete " onClick={this.handleClickBtnDeleteExecutor}/>}
                </div>
                {widget}
            </div>
        }

    });

module.exports = List;
