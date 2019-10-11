const PropTypes = require('prop-types');
const radium = require('radium');

const React = require('react'),
    styles = require('./input-text-styles');

class Input extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: props.value || '',
            readOnly: props.readOnly,
            disabled: props.disabled,
            valid: props.valid
        };
        this.onChange = this.onChange.bind(this);
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

    render() {
        let inputPlaceHolder = this.props.placeholder || this.props.title,
            inputStyle = Object.assign({}, styles.input,
                this.props.width ? {width: this.props.width} : {},
                this.props.style ? this.props.style : {},
                this.state.readOnly ? styles.readOnly : {}
            );

        return (
            <div style={styles.wrapper}>
                <label style={styles.label} htmlFor={this.props.name} ref="label">
                    {this.props.title}
                </label>
                <input type='text'
                       id={this.props.name}
                       ref="input"
                       style={inputStyle}
                       name={this.props.name}
                       value={this.state.value}
                       readOnly={this.state.readOnly}
                       title={this.props.title}
                       pattern={this.props.pattern}
                       placeholder={inputPlaceHolder}
                       onChange={this.onChange}
                       maxLength={this.props.maxLength}
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
    value: PropTypes.string,
    readOnly: PropTypes.bool,
    disabled: PropTypes.bool,
    valid: PropTypes.bool,
    placeholder: PropTypes.string,
    pattern: PropTypes.string,
    title: PropTypes.string
};


Input.defaultProps = {
    readOnly: false,
    disabled: false,
    valid: true,
    value: '',
    title: ''
};

module.exports = radium(Input);