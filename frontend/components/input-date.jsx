'use strict';
const React = require('react');
//    flux = require('fluxify');

const InputDate = React.createClass({
    getInitialState() {
        return {
            value: this.props.value
        };
    },

    getDefaultProps () {
        let date = new Date(),
            year = date.getFullYear(),
            month = date.getMonth(),
            day = date.getDate(),
            maxDate = new Date(year + 1, month, day),
            refId = 'InputDate',
            minDate = new Date(year - 5, month, day);

        return {
            bindData: true,
            min: minDate,
            max: maxDate,
            readOnly: false,
            disabled: false
        };
    },

    componentWillReceiveProps(nextProps) {
        this.setState({value: nextProps.value})
    },


    onChange(e) {
        let fieldValue = e.target.value,
            validation = this.validate(fieldValue);

        if (fieldValue == null) {
            // если значение нул, то пусть будет nul
            validation = true;
        }

        if (validation ) {
            this.setState({value: fieldValue});

            if (this.props.onChange) {
                // если задан обработчик, вернем его
                this.props.onChange(fieldValue);
            }
        }

    },

    propTypes: {
        name: React.PropTypes.string.isRequired
    },

    render() {
        let inputClassName = this.props.className || 'doc-input',
            inputPlaceHolder = this.props.name;

        if (this.props.readOnly) {
            inputClassName = inputClassName + ' doc-input-readonly';
        }
        return <input type='date'
                      className={inputClassName}
                      name={this.props.name}
                      ref={this.props.refId}
                      value={this.state.value}
                      readOnly={this.props.readOnly}
                      title={this.props.title}
                      pattern={this.props.pattern}
                      placeholder={inputPlaceHolder}
                      min={this.props.min}
                      max={this.props.max}
                      onChange={this.onChange}
                      disabled={this.props.disabled}
        />
    },

    validate(value) {
        let result = true;

        // проверка на мин , мах
        if (this.props.min && this.props.max && value) {
            let dateValue = new Date(value);
            result = (dateValue > this.props.min && dateValue < this.props.max);
        }

        return result;
    }

});

module.exports = InputDate;