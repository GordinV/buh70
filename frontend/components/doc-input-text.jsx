var React = require('react'),
    flux = require('fluxify');

const Input = React.createClass({
    getInitialState: function () {
        return {
            value: this.props.value,
            readOnly: this.props.readOnly || false,
            disabled: this.props.disabled || true,
            valid: true
        };
    },
    getDefaultProps: function () {
        return {
            name: 'defaulName',
            className: 'doc-input',
            placeholder: 'defaulName',
            title: '',
            width: 'auto',
            pattern: ''
        }
    },
    componentDidMount: function () {
// создаем обработчик события на изменение docId. Если значение = 0 (добавляем новую запись, то просто очитка полей, иначе подгрузка данных

        flux.stores.docStore.on('change:docId',  (newValue, previousValue)=> {
            if (newValue !== previousValue) {
                // отслеживаем создание нового документа
                var data = flux.stores.docStore.data,
                    value = data[this.props.name];
                if (newValue == 0) {
                    // совый документ
                    this.setState({value: 0});
                } else {
                    this.setState({value: value});
                }
            }
        });

        flux.stores.docStore.on('change:edited', (newValue, previousValue)=> {
            //           console.log('on change:edited:' + newValue);
            if (newValue !== previousValue) {
                this.setState({readOnly: !newValue});
            }
        });

        flux.stores.docStore.on('change:data', (newValue, previousValue)=> {
            // слушуем изменения данных;
//          console.log('input-text on change data:', newValue, previousValue);
            if (newValue !== previousValue) {
                var data = newValue,
                    fieldValue = data[self.props.name];
                if (data[self.props.name]) {
                    this.setState({value: fieldValue});
                }
            }
        });

    },

    componentWillReceiveProps: function (nextProps) {
        this.setState({value: nextProps.value})
    },

    shouldComponentUpdate: function (nextProps, nextState) {
        // изменения будут отражаться только в случае если такие есть

        let returnValue = true;
        if (this.state) {
            returnValue = (nextState.value !== this.state.value ||
            nextState.readOnly !== this.state.readOnly ||
            nextState.disabled !== this.state.disabled);
        }
        return returnValue;
    },

    onChange: function (e) {
        var fieldValue = e.target.value,
            data = flux.stores.docStore.data,
            isPatterValid = true;

        if (this.props.pattern && fieldValue.charAt(fieldValue.length - 1) !== '.') {

            // проводим проверку на соответствие шаблону
            var result = fieldValue.match(this.props.pattern, '');

            if (!result) {
                //              console.log('Pattern vale:' + fieldValue);
                fieldValue = data[this.props.name];
            }
        }
        // только если соответствует паттерну
        this.setState({value: fieldValue});
        //       console.log('onChange fieldValue finish', this.props.name, this.state.value);

        data[this.props.name] = fieldValue;
        // задать новое значение поля
        flux.doAction('dataChange', data);

        /*
         // отдадим обработчику, если задан
         if (this.props.onChange) {
         // смотрим к чему привязан селект и отдаим его наверх
         this.props.onChange(e, this.props.name); // в случае если задан обработчик на верхнем уровне, отдадим обработку туда
         }
         */


    },

    propTypes: {
        name: React.PropTypes.string.isRequired
    },

    render: function () {
        var inputClassName = this.props.className || '' + 'doc-input',
            inputReadOnly = this.state.readOnly || false,
            inputDisabled = this.state.disabled,
            inputPlaceHolder = this.props.placeholder || this.props.name,
            myStyle = {width: 'auto'};

        if (inputReadOnly) {
            inputClassName = inputClassName + ' doc-input-readonly';
        }
        if (this.props.width) {
            myStyle.width = this.props.width
        }

        if (inputDisabled == 'true') {
            return (
                <div className="form-widget">
                    <label htmlFor={this.props.name}
                           className={"form-widget-label" + inputClassName}><span>{this.props.title}</span>
                    </label>
                    <input type='text'
                           style={myStyle}
                           className={inputClassName}
                           name={this.props.name}
                           id={this.props.name}
                           value={this.state.value}
                           readOnly={inputReadOnly}
                           title={this.props.title}
                           pattern={this.props.pattern}
                           placeholder={inputPlaceHolder}
                           onChange={this.onChange}
                           disabled
                    />

                </div>)
        } else {
            return (
                <div className="form-widget">
                    <label>{this.props.title}
                        <input type='text'
                               className={inputClassName}
                               name={this.props.name}
                               value={this.state.value}
                               readOnly={inputReadOnly}
                               title={this.props.title}
                               pattern={this.props.pattern}
                               placeholder={inputPlaceHolder}
                               onChange={this.onChange}
                        />
                    </label>
                </div>)
        }
    }
});

module.exports = Input;