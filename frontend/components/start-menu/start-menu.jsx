'use strict';

const PropTypes = require('prop-types');

const React = require('react');

const styles = require('./start-menu.styles'),
    fetchData = require('./../../../libs/fetchData'),
    TreeList = require('./../tree/tree.jsx');

const DocContext = require('./../../doc-context.js');


const URL = '/newApi/startMenu';

class StartMenu extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            value: props.value
        };

        this.treeData = props.data;
        this.clickHandler = this.clickHandler.bind(this);
        this.fetchData = this.fetchData.bind(this);
    }

    /**
     * пишем делаем запрос по итогу загрузки
     */
    componentDidMount() {
        if (!this.treeData.length) {
            //делаем запрос на получение данных
            this.fetchData(this.props);
        }
    }

    render() {

        return (
            <div style={styles.container}>
                <TreeList ref='treeList'
                          style = {styles.ul}
                          data={this.treeData}
                          bindDataField="kood"
                          value={this.state.value}
                          onClickAction={this.clickHandler}
                />
            </div>
        );
    }

    clickHandler(action, value) {
        if (this.props.clickHandler) {
            return this.props.clickHandler(value);
        }
    }

    /**
     * Выполнит запросы
     */
    fetchData(props) {
        let url = URL + `/${DocContext.getModule}`;
        let params = {userId: DocContext.getUserId, uuid: DocContext.getUuid};
        try {
            // will check in cache
            if (DocContext.getMenu.length == 0) {
                fetchData.fetchDataPost(url, params)
                    .then(response => {
                        if (response.status && response.status == 401) {
                            console.error('Error 401, redirect');
                            document.location = `/login`;
                        }
                        if (response) {

                            this.treeData = response.data.data;
                            // запомним содержимое
                            DocContext.setMenu = this.treeData;
                            this.forceUpdate();
                        }
                    })
                    .catch(error => {
                        console.error('received error-> ', error);
                        if (error) {
                            document.location = `/login`;
                        }
                    });
            } else {
                this.treeData = DocContext.getMenu;
                this.forceUpdate();
            }

        } catch (e) {
            console.error(e);
        }
    }

}


StartMenu.propTypes = {
    data: PropTypes.array
};

StartMenu.defaultProps = {
    data: []
};


module.exports = StartMenu;