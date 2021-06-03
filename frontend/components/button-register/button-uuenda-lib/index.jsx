const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    ICON = 'refresh';


class ButtonUuendaLib extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
    }

    handleClick(e) {
        // если передан обработчик, вернем его
        if (this.props.onClick) {
            return this.props.onClick();
        }

        // если передан документ, вызовем метод обновления библиотеки
        if (this.props.self && this.props.self.loadLibs && this.props.lib) {
            let self = this.props.self;
            self.loadLibs(this.props.lib);
        }
    }

    render() {
        return <Button
            ref="btnUuenda"
            show={this.props.show}
            disabled={this.props.disabled}
            onClick={(e) => this.handleClick(e)}>
            <img ref = 'image' src={styles.icons[ICON]}/>
        </Button>
    }
}

ButtonUuendaLib.defaultProps = {
    disabled: false,
    show: true
};
module.exports = ButtonUuendaLib;