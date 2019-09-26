'use strict';

const PropTypes = require('prop-types');
const {withRouter} = require('react-router-dom');
const fetchData = require('./../../../libs/fetchData');


const React = require('react'),
    ToolbarContainer = require('./../toolbar-container/toolbar-container.jsx'),
    BtnStart = require('./../button-register/button-register-start/button-register-start.jsx'),
    BtnLogin = require('./../button-register/button-login/button-login.jsx'),
    StartMenu = require('./../start-menu/start-menu.jsx'),
    SelectRekv = require('./../select-rekv/index.jsx'),
    BtnAccount = require('./../button-register/button-account/button-account.jsx');

const style = require('./menu-toolbar.styles');

class MenuToolBar extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            logedIn: !!props.userData,
            rekvIds: props.userData ? props.userData.userAccessList : null,
            startMenuValue: 'parentid',
            showStartMenu: false,
            isOpenRekvPage: false
        };

        this.module = props.module;
        this.moduleAddress = this.module === 'Lapsed' ? 'lapsed' : 'raama';

        this.btnStartClick = this.btnStartClick.bind(this);
        this.btnLoginClick = this.btnLoginClick.bind(this);
        this.renderStartMenu = this.renderStartMenu.bind(this);
        this.startMenuClickHandler = this.startMenuClickHandler.bind(this);
        this.handleChange = this.handleChange.bind(this);

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
                }
            };

        const selectStyle = {
            margin: '5px',
            display: 'flex',
            width: '95%'
        };

        const userAccessList = this.props.userData.userAccessList.map((row) => {
            let rowObject = JSON.parse(row);
            return {id: rowObject.id, kood: '', name: rowObject.nimetus};
        });

        const rekvId = this.props.userData.asutusId;
        const module = this.module;

        return (
            <div style={style['container']}>
                <ToolbarContainer
                    ref='menuToolbarContainer'
                    position="left">
                    <BtnStart ref='btnStart'
                              onClick={this.btnStartClick}
                              show={toolbarParams['btnStart'].show}
                              disabled={toolbarParams['btnStart'].disabled}
                    />

                    <SelectRekv name='rekvId'
                                libs="rekv"
                                style={selectStyle}
                                data={userAccessList}
                                readOnly={false}
                                defaultValue={'SAA T'}
                                value={rekvId}
                                collId='id'
                                ref='rekvId'
                                onChange={this.handleChange}/>

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
                </ToolbarContainer>
                {this.renderStartMenu()}

            </div>
        );
    }

    renderStartMenu() {
        let component;
        let module = this.module;
        if (this.state.showStartMenu) {
            component = <StartMenu ref='startMenu'
                                   module={module}
                                   value={this.state.startMenuValue}
                                   userData={this.props.userData}
                                   clickHandler={this.startMenuClickHandler}/>
        }
        return component
    }

    btnStartClick() {
        // обработчик для кнопки Start

        this.setState({showStartMenu: !this.state.showStartMenu});

    }

    /**
     * получит от стартого меню данные, спрячет меню
     */
    startMenuClickHandler(value) {
        this.setState({showStartMenu: false});
        if (this.props.history) {
            return this.props.history.push({
                pathname: `/${this.moduleAddress}/${value}`,
                state: {module: this.moduleAddress}

            });
        } else {
            document.location.href = `/${this.moduleAddress}/${value}`
        }
    }

    btnLoginClick() {
        const URL = '/logout';
        if (this.state.logedIn) {
            this.setState({logedIn: false});

            try {
                let userId = this.props.userData.userId;
                const params = {userId: userId, module: this.module, uuid: this.props.userData.uuid};

                fetchData.fetchDataPost(URL, params).then(() => {
                        document.location.href = '/login';
                    }
                );
            } catch (e) {
                console.error(e);
            }
        } else {
            document.location.href = '/login';
        }
    }


    btnAccountClick() {
        //@todo Страницу с данными пользователся
        console.log('btnAccount');
    }

    handleChange(inputName, inputValue) {
        const URL = '/newApi/changeAsutus';
        let rekvId = inputValue; // choose asutusId

        // отправить пост запрос
        try {
            let localUrl = `${URL}/${rekvId}`;
            let userId = this.props.userData.userId;
            const params = {userId: userId, module: this.module};

            fetchData.fetchDataPost(localUrl, params).then(response => {
                    document.location.reload();
            });

        } catch (e) {
            console.error(e);
        }
        // получить и сохрать данные пользователя
        // обновить регистр документов - перейти на главную страницу
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

module.exports = withRouter(MenuToolBar);