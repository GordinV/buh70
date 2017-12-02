var React = require('react'),
    flux = require('fluxify');

const Input = React.createClass({
    getInitialState: function() {
        return {value: this.props.value, readOnly: true, disabled: this.props.disabled || true};
    },

    getDefaultProps: function () {
        return {
            name: 'defaulName',
            className: 'doc-input',
            placeholder: 'defaulName',
            title: ''
        }
    },

    componentDidMount() {
// создаем обработчик события на изменение docId. Если значение = 0 (добавляем новую запись, то просто очитка полей, иначе подгрузка данных
        flux.stores.docStore.on('change:docId', (newValue, previousValue)=> {
            if (newValue !== previousValue) {
                // отслеживаем создание нового документа
                let data = flux.stores.docStore.data,
                    value = data[this.props.name];
                if (newValue == 0) {
                    // совый документ
                    this.setState({value:0});
                } else {
                    this.setState({value:value});
                }
            }
        });
        flux.stores.docStore.on('change:edited', (newValue, previousValue)=> {
            if (newValue !== previousValue ) {
                this.setState({readOnly: !newValue});
            }
        });
        flux.stores.docStore.on('change:data', (newValue, previousValue)=> {
            // слушуем изменения данных;
            if (JSON.stringify(newValue) !== JSON.stringify(previousValue)) {
                let data = newValue,
                    fieldValue = data[this.props.name];
                if (data[this.props.name]) {
                    this.setState({value: fieldValue});
                }
            }
        });

    },

    shouldComponentUpdate(nextProps, nextState) {
        // изменения будут отражаться только в случае если такие есть
        let returnvalue = (nextState.value !== this.state.value ||
        nextState.readOnly !== this.state.readOnly ||
        nextState.disabled !== this.state.disabled);
        return returnvalue;
    },

    onChange: function(e) {
        let fieldValue = e.target.value,
            data = flux.stores.docStore.data;

        this.setState({value: fieldValue});
        data[this.props.name] = fieldValue;
        // задать новое значение поля
        flux.doAction('dataChange', data);

    },

    componentWillReceiveProps: function(nextProps) {
        this.setState({value:nextProps.value })
    },

    render: function() {
        var inputClassName =this.props.className || 'doc-input',
            inputReadOnly = this.state.readOnly || false,
            inputDisabled = this.state.disabled,
            inputPlaceHolder = this.props.placeholder || this.props.name,
            myStyle = {width:'auto'};;

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
                       className="form-widget-label"><span>{this.props.title}</span>
                </label>
                <textarea
                        style={myStyle}
                          className={inputClassName}
                          id={this.props.name}
                          name={this.props.name}
                          value={this.state.value}
                          readOnly={inputReadOnly}
                          title={this.props.title}
                          placeholder={inputPlaceHolder}
                          onChange={this.onChange}
                          disabled
            />
            </div>)
        } else {
            return (
                <div className="form-widget">
                    <label htmlFor={this.props.name}
                           className="form-widget-label"><span>{this.props.title}</span>
                    </label>
                <textarea
                    style={myStyle}
                    className={inputClassName}
                    id={this.props.name}
                    name={this.props.name}
                    value={this.state.value}
                    readOnly={inputReadOnly}
                    title={this.props.title}
                    placeholder={inputPlaceHolder}
                    onChange={this.onChange}
                />
                </div>)
        }
    },

    propTypes: {
        name: React.PropTypes.string.isRequired
    },

});

module.exports = Input;