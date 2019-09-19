import React, { createContext } from 'react';

const UserContext = createContext({
    username: '',
    updateUsername: () => {},
});

export class UserProvider extends React.Component {
    updateUsername = newUsername => {
        this.setState({ username: newUsername });
    };
    state = {
        username: 'user',
        updateUsername: this.updateUsername,
    };
    render() {
        return (
            <UserContext.provider value="{this.state}">
                {this.props.children}
            </UserContext.provider>
        );
    }
}

export const UserConsumer = UserContext.Consumer;