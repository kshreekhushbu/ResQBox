import React, { Component, ReactNode } from "react";
interface ErrorBoundaryProps {
  children: ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  isOffline: boolean;
}

class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false, isOffline: !navigator.onLine };
  }

  static getDerivedStateFromError(): ErrorBoundaryState {
    return { hasError: true, isOffline: false };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
    console.error("ErrorBoundary caught an error", error, errorInfo);
  }

  componentDidMount() {
    window.addEventListener("online", this.handleOnline);
    window.addEventListener("offline", this.handleOffline);
  }

  componentWillUnmount() {
    window.removeEventListener("online", this.handleOnline);
    window.removeEventListener("offline", this.handleOffline);
  }

  handleOnline = () => {
    this.setState({ isOffline: false });
  };

  handleOffline = () => {
    this.setState({ isOffline: true });
  };

  render() {
    if (this.state.isOffline) {
      return (
        <div className="w-full min-h-screen flex flex-col items-center justify-center text-center py-12 px-6">
          <div className="text-6xl mb-4">📡</div>
          <h1 className="mt-6 text-4xl font-bold text-foreground">
            You are offline
          </h1>
          <p className="mt-2 text-lg text-muted-foreground">
            Please check your internet connection and try again.
          </p>
        </div>
      );
    }

    if (this.state.hasError) {
      return (
        <div className="w-full min-h-screen flex flex-col items-center justify-center text-center py-12 px-6">
          <div className="text-6xl mb-4">⚠️</div>
          <h1 className="mt-6 text-4xl font-bold text-foreground">
            Something went wrong
          </h1>
          <p className="mt-2 text-lg text-muted-foreground">
            Please try refreshing the page or contact support if the issue
            persists.
          </p>
          <button
            onClick={() => window.location.reload()}
            className="mt-6 px-4 py-2 bg-primary text-white rounded-md hover:bg-primary/90"
          >
            Refresh Page
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

export default ErrorBoundary;
