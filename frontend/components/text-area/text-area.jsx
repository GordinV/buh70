const React = require('react'),
    styles = require('./text-area-styles');
const radium = require('radium');

const PropTypes = require('prop-types');


class Input extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: props.value || '' ,
            readOnly: true,
            disabled: props.disabled || true
        };

        this.onChange = this.onChange.bind(this);

    }

    onChange(e) {
        let fieldValue = e.target.value;

        this.setState({value: fieldValue});
        if (this.props.onChange) {
            this.props.onChange(this.props.name, fieldValue);
        }
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.value !== prevState.value || nextProps.readOnly !== prevState.readOnly) {
            return {value: nextProps.value, readOnly: nextProps.readOnly};
        } else return null;
    }


    render() {
        const inputPlaceHolder = this.props.placeholder || this.props.title,
            inputStyle = Object.assign({}, styles.input,
                this.props.width ? {width: this.props.width} : {},
                this.state.readOnly ? styles.readOnly : {},
                this.props.style ? this.props.style: {}
            );

        return (
            <div style={styles.wrapper}>

                <label htmlFor={this.props.name} ref="label"
                       style={styles.label}><span>{this.props.title}</span>
                </label>

                <textarea
                    style={inputStyle}
                    ref="input"
                    id={this.props.name}
                    name={this.props.name}
                    value={this.state.value || ''}
                    readOnly={this.props.readOnly}
                    title={this.props.title}
                    placeholder={inputPlaceHolder}
                    onChange={this.onChange}
                    disabled={this.props.disabled}
                />
            </div>)
    }

}

Input.propTypes = {
    name: PropTypes.string.isRequired,
    value: PropTypes.string,
    readOnly: PropTypes.bool,
    disabled: PropTypes.bool,
    valid: PropTypes.bool,
    placeholder: PropTypes.string,
    title: PropTypes.string
};

Input.defaultProps = {
    readOnly: false,
    disabled: false,
    valid: true,
    title: '',
    value: ''
};


module.exports = radium(Input);