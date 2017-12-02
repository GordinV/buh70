'use strict';

//import PropTypes from 'prop-types';

const React = require('react');;
import flux from 'fluxify';

class InputDateTime extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: this.props.value, readOnly: true, disabled: this.props.disabled || true
        };
    }

    componentWillMount() {
// создаем обработчик события на изменение docId. Если значение = 0 (добавляем новую запись, то просто очитка полей, иначе подгрузка данных
        const self = this;

        flux.stores.docStore.on('change:edited',  (newValue, previousValue) => {
            //           console.log('on change:edited:' + newValue);
            if (newValue !== previousValue) {
                self.setState({readOnly: !newValue});
            }
        });

        flux.stores.docStore.on('change:data', (newValue, previousValue)=> {
            if (newValue !== previousValue) {

                var data = newValue,
                    fieldValue = data[self.props.name];

                self.setState({value: fieldValue});
            }
        });
    }

    shouldComponentUpdate (nextProps, nextState) {
        // изменения будут отражаться только в случае если такие есть
        var returnvalue = (nextState.value !== this.state.value ||
        nextState.readOnly !== this.state.readOnly ||
        nextState.disabled !== this.state.disabled);

        //       console.log('vastus:' + returnvalue);
        return returnvalue;

    }

    onChange (e) {
        let fieldValue = e.target.value,
            data = flux.stores.docStore.data;

        this.setState({value: fieldValue});
        data[this.props.name] = fieldValue;

        // задать новое значение поля
        flux.doAction('dataChange', data);
    }
    render() {
        let inputClassName = this.props.className || 'doc-input',
            inputReadOnly = this.state.readOnly || false,
            inputDisabled = this.state.disabled,
            inputPlaceHolder = this.props.placeholder || this.props.name;

        if (inputReadOnly) {
            inputClassName = inputClassName + ' doc-input-readonly';
        }

        if (inputDisabled == 'true') {
            return (
                <div className="form-widget">
                    <label>{this.props.title}</label>
                    <input type='datetime-local'
                           className={inputClassName}
                           name={this.props.name}
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
                    <label>{this.props.title}</label>
                    <input type='datetime-local'
                           className={inputClassName}
                           name={this.props.name}
                           value={this.state.value}
                           readOnly={inputReadOnly}
                           title={this.props.title}
                           pattern={this.props.pattern}
                           placeholder={inputPlaceHolder}
                           onChange={this.onChange}
                    />
                </div>)
        }
    }
}

module.exports = InputDateTime;