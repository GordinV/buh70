const PropTypes = require('prop-types');
const radium = require('radium');

const React = require('react'),
    styles = require('./styles');

class Input extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: Boolean(props.value),
            readOnly: props.readOnly,
            disabled: props.disabled,
        };
        this.onChange = this.onChange.bind(this);
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.value !== prevState.value || nextProps.readOnly !== prevState.readOnly) {
            return {value: nextProps.value, readOnly: nextProps.readOnly};
        } else return null;
    }

    componentDidMount() {
        this.refs['checkbox'].checked = this.state.value;
    }


    onChange(e) {
        let value = e.target.checked;

        this.setState({value: value});

        if (!this.state.readOnly && this.props.onChange) {
            this.props.onChange(this.props.name, value);
        }
    }

    render() {
        let inputStyle = Object.assign({}, styles.input,
            this.props.width ? {width: this.props.width} : {},
            this.state.readOnly ? styles.readOnly : {}
        );

        return (
            <div style={styles.wrapper}>
                <label style={styles.label} htmlFor={this.props.name} ref="label">
                    {this.props.title}
                </label>
                <input type='checkbox'
                       id={this.props.name}
                       ref="checkbox"
                       style={inputStyle}
                       name={this.props.name}
                       value={this.state.value}
                       checked={this.state.value}
                       readOnly={this.state.readOnly}
                       onChange={this.onChange}
                       disabled={this.state.readOnly}
                />

            </div>)
    }

    /**
     * установит фокус на элементы
     */
    focus() {
        this.refs['checkbox'].focus();
    }

}

Input.propTypes = {
    name: PropTypes.string.isRequired,
    value: PropTypes.bool,
    readOnly: PropTypes.bool,
    disabled: PropTypes.bool,
    title: PropTypes.string
};


Input.defaultProps = {
    readOnly: false,
    disabled: false,
    value: false,
    title: ''
};

module.exports = radium(Input);