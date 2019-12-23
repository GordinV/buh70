'use strict';

const React = require('react');
const PropTypes = require('prop-types');
const DocContext = require('./../../../doc-context.js');

const styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'info';


class ButtonLogs extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);

        this.state = {
            value: props.value || 'Logid'
        }

    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.value !== prevState.value) {
            return {value: nextProps.value};
        } else return null;
    }


    handleClick(e) {
        if (this.props.onClick) {
            return this.props.onClick('logid');
        } else {
            //redirect
            this.props.history.push(`/${DocContext.module}/pank_vv`);
        }
    }

    render() {

        return <Button
            value={this.state.value}
            ref="btnLogid"
            style={styles.button}
            show={this.props.show ? this.props.show: true}
            onClick={(e) => this.handleClick(e)}>
            <img ref="image" src={styles.icons[ICON]}/>
        </Button>
    }
}

ButtonLogs.propTypes = {
    value: PropTypes.string
};


ButtonLogs.defaultProps = {
    disabled: false,
    show: true,
    value: 'Logid'
};

module.exports = ButtonLogs;