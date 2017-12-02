'use strict';

var React = require('react'),
    flux = require('fluxify');
//    InputText = require('./doc-input-text.jsx');

const Select = React.createClass({
    getInitialState: function () {
        var libData = [];
        var libs = flux.stores.docStore.libs,
        // грузим данные из хранилища
            data = libs.filter(function (item) {
                if (item.id == this.props.libs) {
                    return item;
                }
            }, this),
            idValue = this.props.value; // для привязки данных

        if (data && data.length > 0 && data[0].data) {
            libData = data[0].data;
        }

        return {value: this.props.value /* здесь по значению ИД */,
            readOnly: this.props.readOnly,
            disabled: true,
            data: libData || [],
            fieldValue: this.props.value /*здесь по значени поля collId */,
            brnDelete: this.props.btnDelete /* если истину, то рисуем рядом кнопку для очистки значения*/};
    },

    findFieldValue: function (data, collId, value) {
        // привяжет к значеню поля
        // надо привязать данные
        // kood -> id
        var id = 0;
        data.forEach(function (row) {
            if (row[collId] == value) {
                id = row.id;
//                return id;
                this.setState({value: row.id, fieldValue: row[collId]});
                return;
            }
        }, this);

    },

    getValueById: function(collId, rowId) {
        // вернет значения поля по выбранному ИД

        var fieldValue,
            data = this.state.data;

        data.forEach(function (row) {
            if (row['id'] == rowId) {
                fieldValue = row[collId];
                this.setState({fieldValue: fieldValue});
            }
        }, this);

    },

    getDefaultProps: function () {
        // покажет значение по умолчанию для виджета, пока грузится справочник
        return {
            defaultValue: null,
            value: null,
            title: null,
            btnDelete: false
        };
    },

    componentWillMount: function () {
// создаем обработчик события на изменение docId. Если значение = 0 (добавляем новую запись, то просто очитка полей, иначе подгрузка данных
        var self = this;

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

    componentDidMount: function () {
        if (this.props.collId && this.props.collId !== 'id') {
            // ищем ИД по значению поля
            this.findFieldValue(this.state.data, this.props.collId, this.props.value);
        }

    },

    onChange: function (e) {

        var fieldValue = e.target.value,
            data = flux.stores.docStore.data,
            propValue = data[this.props.name];

        if (fieldValue == '') {
            fieldValue = null;
        }
        
        // найдем по ид значение поля в collId
        this.getValueById(this.props.collId, fieldValue);
        // сохраним ид как value

        this.setState({value:fieldValue});

        if (propValue !== 'undefined') {
            // если используется привязка к данным
            // получить значение
            data[this.props.name] = fieldValue;
            // задать новое значение поля
            flux.doAction('dataChange', data);
        }

        if (this.props.onChange) {
            // смотрим к чему привязан селект и отдаим его наверх
            this.props.onChange(e, this.props.name, this.state.value); // в случае если задан обработчик на верхнем уровне, отдадим обработку туда
        }

    },

    render: function () {
        var dataOptions = this.state.data || [],
            inputClassName = this.props.className || 'doc-input',
            inputReadOnly = this.state.readOnly || false,
            inputPlaceHolder = this.props.placeholder || this.props.name,
            Options = null,
            inputDefaultValue = this.props.defaultValue; // Дадим дефолтное значение для виджета, чтоб покать его сразу, до подгрузки библиотеки

        if (this.props.dok) {
            // оставим только заданый "справочник"
            dataOptions = dataOptions.filter(item => {
                if (item.dok === this.props.dok) {
                    return item;
                }
            })
        }

        if (!this.state.value) { // добавим пустую строку в массив
            // проверим наличие пустой строки в массиве

            let emptyObj = dataOptions.filter((obj) => {
                if (obj.id === 0) {
                    return obj;
                }
            });

            if (!emptyObj || emptyObj.length == 0) {
                dataOptions.splice(0, 0, {id: 0, kood: '', name: ''});
            }

        }

        var dataValue = dataOptions.filter(function (item) {
            if (item.id == this.state.value) {
                return item;
            }
        }, this);

        if (dataOptions.length) {
            Options = dataOptions.map(function (item) {

                if (typeof item == 'array') {
                    item = item[0];
                }
                return <option value={item.id} key={Math.random()} >{item.name}</option>
            }, this);
            inputDefaultValue = dataValue.length > 0 ? dataValue[0].name : this.props.defaultValue;
        } else {
            Options = <option value={0} key= {Math.random()}> Empty </option>
        }

        var widget = <select value={this.state.value} onChange={this.onChange}
                             style={{width:'100%', height:'100%'}}>{Options}</select>; // если для грида, оставим только селект
        
        if (this.props.title) {
            widget = (<div className="form-widget">
                <label className="form-widget-label">{this.props.title}
                <div style={{display:'inline-block'}}>
                    {inputReadOnly ?
                        <input type="text" className='ui-c1 doc-input-readonly' value={inputDefaultValue}
                               readOnly="true"/> : null}
                    {inputReadOnly ? null :
                        <div>
                            <select className='ui-c2' value={this.state.value} onChange={this.onChange}>{Options}</select>
                            {this.props.btnDelete ?
                            <button className ='ui-c1-button' onClick = {this.btnDelClick}> Delete </button> : null }
                        </div>
                    }
                </div>
                </label>
            </div>);
        }
        return <div>{widget}</div>
    },

    btnDelClick: function(event) {
        // по вызову кнопку удалить, обнуляет значение
        this.setState({value:null});
        this.onChange(event);
    }
});

module.exports = Select;
