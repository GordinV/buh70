'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    ToolbarContainer = require('./../toolbar-container/toolbar-container.jsx'),
    BtnStart = require('./../button-register/button-register-start/button-register-start.jsx'),
    BtnLogin = require('./../button-register/button-login/button-login.jsx'),
    BtnRekv = require('./../button-register/button-rekv/button-rekv.jsx'),
    BtnAccount = require('./../button-register/button-account/button-account.jsx');

const style = require('./menu-toolbar.styles');

class MenuToolBar extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            logedIn: !!props.userData,
            rekvIds: props.userData ? props.userData.userAccessList : null
        };

        this.btnStartClick = this.btnStartClick.bind(this);
        this.btnLoginClick = this.btnLoginClick.bind(this);

    }

    render() {
        let isEditMode = this.props.edited,
            toolbarParams = {
                btnStart: {
                    show: this.props.params['btnStart'].show || false,
                    disabled: isEditMode
                },
                btnLogin: {
                    show: true,
                    disabled: false
                },
                btnAccount: {
                    show: this.state.logedIn || false,
                    disabled: false
                },
                btnRekv: {
                    show: this.state.logedIn || false,
                    disabled: !this.state.rekvIds
                }


            };

        return (
            <div style={style['container']}>
                <ToolbarContainer
                    ref='menuToolbarContainer'
                    position="left">
                    <div>
                        <BtnStart ref='btnStart'
                                  onClick={this.btnStartClick}
                                  show={toolbarParams['btnStart'].show}
                                  disabled={toolbarParams['btnStart'].disabled}/>
                        <BtnRekv ref='btnRekv'
                                 value={this.props.userData ? this.props.userData.asutus : ''}
                                 onClick={this.btnRekvClick}
                                 show={toolbarParams['btnRekv'].show}
                                 disabled={toolbarParams['btnRekv'].disabled}/>
                        <BtnAccount ref='btnAccount'
                                    value={this.props.userData ? this.props.userData.userName : ''}
                                    onClick={this.btnAccountClick}
                                    show={toolbarParams['btnAccount'].show}
                                    disabled={toolbarParams['btnAccount'].disabled}/>
                        <BtnLogin ref='btnLogin'
                                  value={this.state.logedIn ? 'LogOut' : 'LogIn'}
                                  onClick={this.btnLoginClick}
                                  show={toolbarParams['btnLogin'].show}
                                  disabled={toolbarParams['btnLogin'].disabled}/>
                    </div>
                </ToolbarContainer>
            </div>
        );
    }

    btnStartClick() {
        // обработчик для кнопки Start
        if (this.props.btnStartClick) {
            return this.props.btnStartClick();
        }

        if (document) {
            document.location.href = '/documents';
        }
    }

    btnLoginClick() {

        if (this.state.logedIn) {
            this.setState({logedIn: false});
            document.location.href = '/logout';
        } else {
            document.location.href = '/login';

        }
    }


    btnAccountClick() {
        //@todo Страницу с данными пользователся
        console.log('btnAccount');
    }

    btnRekvClick() {
        if (document) {
            document.location.href = '/changeDepartment';
        }

    }
}

/*
MenuToolBar
    .propTypes = {
    edited: PropTypes.bool,
    params: PropTypes.object.isRequired,
    logedIn: PropTypes.bool
};


MenuToolBar
    .defaultProps = {
    edited: false,
    logedIn: false,
    params: {
        btnStart: {
            show: true
        }
    }
};
*/

module.exports = MenuToolBar;