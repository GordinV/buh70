const React = require('react'),
    ComponentInputDate = require('./input-date.jsx'),
    flux = require('fluxify');

const InputDate = React.createClass({
    getInitialState: function () {
        return {
            value: this.props.value,
            readOnly: true,
            disabled: this.props.disabled || true,
            valid: true
        };
    },

    getDefaultProps: function () {

        var date = new Date(),
            year = date.getFullYear(),
            month = date.getMonth(),
            day = date.getDate(),
            maxDate = new Date(year + 1, month, day),
            minDate = new Date(year - 1, month, day);

        return {
            bindData: true,
            min: minDate,
            max: maxDate
        };
    },

    componentWillReceiveProps: function (nextProps) {
        this.setState({value: nextProps.value})
    },

    componentDidMount() {
        // событие на изменение режима редактирования
        flux.stores.docStore.on('change:edited', (newValue, previousValue) => {
            if (newValue !== previousValue) {
                this.setState({readOnly: !newValue});
            }
        });
    },
    /*
     componentWillMount: function() {
     // создаем обработчик события на изменение docId. Если значение = 0 (добавляем новую запись, то просто очитка полей, иначе подгрузка данных
     var self = this;
     //        console.log('componentWillMount' + this.props.name);
     /!*
     flux.stores.docStore.on('change:docId', function(newValue, previousValue) {
     if (newValue !== previousValue) {
     // отслеживаем создание нового документа
     /!*
     var data = flux.stores.docStore.data,
     value = data[self.props.name];

     if (newValue == 0) {
     // новый документ
     self.setState({value:0});
     } else {
     self.setState({value:value});
     }
     *!/
     }
     });
     *!/

     flux.stores.docStore.on('change:edited', function(newValue, previousValue) {
     //           console.log('on change:edited:' + newValue);
     if (newValue !== previousValue) {
     self.setState({readOnly: !newValue});
     }
     });

     /!*
     flux.stores.docStore.on('change:data', function(newValue, previousValue) {
     console.log('on change:data:' + newValue);
     if (newValue !== previousValue) {

     var data = newValue,
     fieldValue = data[self.props.name];

     self.setState({value: fieldValue});
     }
     });

     *!/

     },
     */
    // обязательные параметры
    propTypes: {
        name: React.PropTypes.string.isRequired
     },


    onChange: function (fieldValue) {
        let data = flux.stores.docStore.data;
        this.setState({value: fieldValue});
        data[this.props.name] = fieldValue;

        // задать новое значение поля
        flux.doAction('dataChange', data);
    },

    render: function () {
        let inputClassName = this.props.className || 'doc-input',
            inputReadOnly = this.state.readOnly || false,
            inputDisabled = this.state.disabled == 'true' ? true : false,
            inputPlaceHolder = this.props.placeholder || this.props.name;

        if (inputReadOnly) {
            inputClassName = inputClassName + ' doc-input-readonly';
        }
        return (
            <div className="form-widget">
                <label htmlFor={this.props.name}>
                    {this.props.title}
                </label>

                <ComponentInputDate
                    className={inputClassName}
                    name={this.props.name}
                    value={this.state.value}
                    readOnly={inputReadOnly}
                    title={this.props.title}
                    pattern={this.props.pattern}
                    placeholder={inputPlaceHolder}
                    onChange={this.onChange}
                    disabled={inputDisabled}
                />
            </div>)
    }
});

module.exports = InputDate;