const React = require('react'),
    styles = require('./input-number-styles');
const radium = require('radium');

const PropTypes = require('prop-types');
const Button = require('./../button-register/button-register.jsx');

class Input extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: props.value,
            readOnly: props.readOnly,
            disabled: props.disabled,
            valid: props.valid
        };
        this.onChange = this.onChange.bind(this);
//        this.handleClick = this.handleClick(this);
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.value !== prevState.value || nextProps.readOnly !== prevState.readOnly) {
            return {value: nextProps.value, readOnly: nextProps.readOnly};
        } else return null;
    }


    onChange(e) {
        let fieldValue = e.target.value;
        this.setState({value: fieldValue});


        if (this.props.onChange) {
            this.props.onChange(this.props.name, fieldValue);
        }
    }

    handleClick() {
        let value = -1 * Number(this.state.value);
        this.setState({value: value});
        if (this.props.onChange) {
            this.props.onChange(this.props.name, value);
        }
    }

    render() {
        let inputPlaceHolder = this.props.placeholder || this.props.name,
            inputStyle = Object.assign({}, styles.input,
                this.props.style ? this.props.style : {},
                this.props.width ? {width: this.props.width} : {},
                this.state.readOnly ? styles.readOnly : {}
            ),
            inputMinValue = this.props.min,
            inputMaxValue = this.props.max;

        return (
            <div style={styles.wrapper}>
                <label style={styles.label} htmlFor={this.props.name} ref="label">
                    {this.props.title}
                </label>
                {/*
                {this.state.readOnly || this.props.disabled ? null :
                    <Button
                        style={styles.button}
                        value={'-'}
                        ref="btnMinus"
                        show={!this.state.readOnly}
                        title={'Pane miinus'}
                        onClick={(e) => this.handleClick(e)}>
                    </Button>}
*/}
                <input type={this.props.type ? this.props.type : 'number'}
                       id={this.props.name}
                       ref="input"
                       style={inputStyle}
                       name={this.props.name}
                       value={this.state.value}
                       readOnly={this.state.readOnly}
                       title={this.props.title}
                       placeholder={inputPlaceHolder}
                       onChange={this.onChange}
                       min={inputMinValue}
                       max={inputMaxValue}
                       step="0.01"
                       pattern="[-+]?[0-9]*[.,]?[0-9]+"
                       disabled={this.props.disabled}
                />
            </div>)
    }


    /**
     * установит фокус на элементы
     */
    focus() {
        this.refs['input'].focus();
    }

}

Input.propTypes = {
    name: PropTypes.string.isRequired,
    value: PropTypes.number,
    readOnly: PropTypes.bool,
    disabled: PropTypes.bool,
    valid: PropTypes.bool,
    placeholder: PropTypes.string,
    pattern: PropTypes.string,
    title: PropTypes.string,
    min: PropTypes.number,
    max: PropTypes.number
};


Input.defaultProps = {
    readOnly: false,
    disabled: false,
    valid: true,

};

module.exports = radium(Input);