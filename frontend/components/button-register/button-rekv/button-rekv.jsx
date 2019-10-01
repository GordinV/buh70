'use strict';

const React = require('react');
const PropTypes = require('prop-types');

const styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'rekv';


class ButtonRekv extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);

        this.state = {
            value: props.value
        }

    }

    componentWillReceiveProps(nextProps) {
        this.setState({value: nextProps.value});
    }

    handleClick(e) {
        return this.props.onClick('rekv');
    }

    render() {
        let value = this.state.value;

        return <Button
            value={this.props.value}
            ref="btnRekv"
            style={styles.button}
            show={this.props.show}
            disabled={this.props.disabled}
            onClick={(e) => this.handleClick(e)}>
            <img ref="image" src={styles.icons[ICON]}/>
        </Button>
    }
}

ButtonRekv.propTypes = {
    onClick: PropTypes.func.isRequired,
    value: PropTypes.string
};


ButtonRekv.defaultProps = {
    disabled: false,
    show: true,
    value: ''
};

module.exports = ButtonRekv;