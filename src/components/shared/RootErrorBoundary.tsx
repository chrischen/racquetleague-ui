import React from 'react';
import { useRouteError, isRouteErrorResponse } from 'react-router-dom';
import { make as NotFoundDefault } from '../pages/NotFoundDefault.gen';
import { isInvalidLanguageError } from './Lang.gen';

export const RootErrorBoundary: React.FC = () => {
  const error = useRouteError();

  // If it's an invalid language error, render the NotFoundDefault component
  if (isInvalidLanguageError(error as {[id: string]: unknown})) {
    return <NotFoundDefault />;
  }

  let errorMessage: string;
  let errorStatus: number | undefined;

  if (isRouteErrorResponse(error)) {
    // React Router error response (like 404, 500, etc.)
    errorMessage = error.data?.message || error.statusText || 'An error occurred';
    errorStatus = error.status;
  } else if (error instanceof Error) {
    // JavaScript error
    errorMessage = error.message;
  } else if (typeof error === 'string') {
    errorMessage = error;
  } else {
    errorMessage = 'An unexpected error occurred';
  }

  // Log error to console in development
  if (process.env.NODE_ENV === 'development') {
    console.error('Router Error:', error);
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full bg-white shadow-lg rounded-lg p-6">
        <div className="flex items-center mb-4">
          <div className="flex-shrink-0">
            <svg
              className="h-8 w-8 text-red-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.268 15.5c-.77.833.192 2.5 1.732 2.5z"
              />
            </svg>
          </div>
          <div className="ml-3">
            <h1 className="text-lg font-medium text-gray-900">
              {errorStatus ? `Error ${errorStatus}` : 'Something went wrong'}
            </h1>
          </div>
        </div>
        
        <div className="mb-4">
          <p className="text-sm text-gray-600">
            {errorMessage}
          </p>
        </div>

        <div className="flex space-x-3">
          <button
            onClick={() => window.location.reload()}
            className="flex-1 bg-blue-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            Reload Page
          </button>
          <button
            onClick={() => window.history.back()}
            className="flex-1 bg-gray-300 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-500"
          >
            Go Back
          </button>
        </div>
      </div>
    </div>
  );
};